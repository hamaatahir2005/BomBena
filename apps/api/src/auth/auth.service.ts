import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AccountStatus, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RegisterDto } from './auth.dto';

const SAFE_USER_SELECT = { id: true, email: true, phone: true, status: true, roles: true } as const;

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService, private readonly jwt: JwtService, private readonly config: ConfigService) {}

  async register(dto: RegisterDto) {
    if (!dto.email && !dto.phone) throw new ConflictException('Email or phone is required');
    const passwordHash = await bcrypt.hash(dto.password, 12);
    try {
      const user = await this.prisma.user.create({
        data: {
          email: dto.email?.toLowerCase(), phone: dto.phone, passwordHash,
          status: AccountStatus.ACTIVE, roles: [UserRole.CUSTOMER],
          customerProfile: { create: { displayName: dto.displayName } },
        }, select: SAFE_USER_SELECT,
      });
      return this.issueTokens(user);
    } catch (error) {
      if (this.isUniqueViolation(error)) throw new ConflictException('Email or phone is already registered');
      throw error;
    }
  }

  async login(dto: LoginDto) {
    const identifier = dto.identifier.includes('@') ? dto.identifier.toLowerCase() : dto.identifier;
    const user = await this.prisma.user.findFirst({ where: { OR: [{ email: identifier }, { phone: identifier }] } });
    if (!user?.passwordHash || user.status !== AccountStatus.ACTIVE || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.issueTokens({ id: user.id, email: user.email, phone: user.phone, status: user.status, roles: user.roles });
  }

  async refresh(rawToken: string) {
    let claims: { sub: string; jti: string; typ: string };
    try {
      claims = await this.jwt.verifyAsync(rawToken, { secret: this.config.getOrThrow('JWT_REFRESH_SECRET') });
    } catch { throw new UnauthorizedException('Invalid refresh token'); }
    if (claims.typ !== 'refresh' || !claims.sub || !claims.jti) throw new UnauthorizedException('Invalid refresh token');
    const record = await this.prisma.refreshToken.findUnique({ where: { id: claims.jti }, include: { user: true } });
    if (!record || record.revokedAt || record.expiresAt <= new Date() || !(await bcrypt.compare(rawToken, record.tokenHash))) {
      throw new UnauthorizedException('Refresh token expired or revoked');
    }
    const user = record.user;
    if (user.status !== AccountStatus.ACTIVE) throw new UnauthorizedException('Account is not active');
    const tokens = await this.makeTokens(user);
    const hash = await bcrypt.hash(tokens.refreshToken, 12);
    await this.prisma.$transaction(async (tx) => {
      const result = await tx.refreshToken.updateMany({ where: { id: record.id, revokedAt: null }, data: { revokedAt: new Date(), replacedBy: tokens.refreshId } });
      if (result.count !== 1) throw new UnauthorizedException('Refresh token already used');
      await tx.refreshToken.create({ data: { id: tokens.refreshId, userId: user.id, tokenHash: hash, expiresAt: tokens.refreshExpiresAt } });
    });
    return { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user: this.publicUser(user) };
  }

  async logout(rawToken: string): Promise<{ success: true }> {
    try {
      const claims = await this.jwt.verifyAsync<{ jti?: string; typ?: string }>(rawToken, { secret: this.config.getOrThrow('JWT_REFRESH_SECRET') });
      if (claims.typ === 'refresh' && claims.jti) await this.prisma.refreshToken.updateMany({ where: { id: claims.jti, revokedAt: null }, data: { revokedAt: new Date() } });
    } catch { /* logout is idempotent; invalid tokens are simply discarded client-side */ }
    return { success: true };
  }

  private async issueTokens(user: { id: string; email: string | null; phone: string | null; status: AccountStatus; roles: UserRole[] }) {
    const tokens = await this.makeTokens(user);
    const tokenHash = await bcrypt.hash(tokens.refreshToken, 12);
    await this.prisma.refreshToken.create({ data: { id: tokens.refreshId, userId: user.id, tokenHash, expiresAt: tokens.refreshExpiresAt } });
    return { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user: this.publicUser(user) };
  }

  private async makeTokens(user: { id: string; roles: UserRole[] }) {
    const refreshId = randomUUID();
    const days = Number(this.config.get('JWT_REFRESH_TTL_DAYS', '30'));
    const refreshExpiresAt = new Date(Date.now() + days * 86_400_000);
    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync({ sub: user.id, roles: user.roles, typ: 'access' }, { secret: this.config.getOrThrow('JWT_ACCESS_SECRET'), expiresIn: this.config.get('JWT_ACCESS_TTL', '15m') }),
      this.jwt.signAsync({ sub: user.id, jti: refreshId, typ: 'refresh' }, { secret: this.config.getOrThrow('JWT_REFRESH_SECRET'), expiresIn: `${days}d` }),
    ]);
    return { accessToken, refreshToken, refreshId, refreshExpiresAt };
  }

  private publicUser(user: { id: string; email: string | null; phone: string | null; status: AccountStatus; roles: UserRole[] }) {
    return { id: user.id, email: user.email, phone: user.phone, status: user.status, roles: user.roles };
  }

  private isUniqueViolation(error: unknown): boolean { return !!error && typeof error === 'object' && 'code' in error && error.code === 'P2002'; }
}
