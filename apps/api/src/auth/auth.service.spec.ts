import { ConflictException } from '@nestjs/common';
import { AuthService } from './auth.service';

const prisma = {
  user: { create: jest.fn(), findFirst: jest.fn() },
  refreshToken: { create: jest.fn(), findUnique: jest.fn(), updateMany: jest.fn() },
  $transaction: jest.fn(),
};
const jwt = { signAsync: jest.fn() };
const config = { get: jest.fn((key: string, fallback?: string) => ({ JWT_ACCESS_TTL: '15m', JWT_REFRESH_TTL_DAYS: '30' }[key] ?? fallback)), getOrThrow: jest.fn((key: string) => `${key}-a-secret-that-is-long-enough`) };

describe('AuthService', () => {
  let service: AuthService;
  beforeEach(() => {
    jest.clearAllMocks();
    service = new AuthService(prisma as never, jwt as never, config as never);
    jwt.signAsync.mockResolvedValueOnce('access.jwt').mockResolvedValueOnce('refresh.jwt');
  });

  it('requires a phone or email on registration', async () => {
    await expect(service.register({ password: 'very-long-password' })).rejects.toBeInstanceOf(ConflictException);
  });

  it('creates a customer identity and never returns the password hash', async () => {
    prisma.user.create.mockResolvedValue({ id: 'user-1', email: 'a@example.com', phone: null, status: 'ACTIVE', roles: ['CUSTOMER'] });
    prisma.refreshToken.create.mockResolvedValue({});
    const result = await service.register({ email: 'A@example.com', password: 'very-long-password', displayName: 'A User' });
    expect(prisma.user.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ email: 'a@example.com', roles: ['CUSTOMER'] }) , select: expect.any(Object) }));
    expect(result).toEqual(expect.objectContaining({ accessToken: 'access.jwt', refreshToken: 'refresh.jwt', user: expect.objectContaining({ id: 'user-1' }) }));
    expect(JSON.stringify(result)).not.toContain('passwordHash');
  });
});
