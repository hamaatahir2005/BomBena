import { IsEmail, IsOptional, IsString, Matches, MinLength } from 'class-validator';

export class RegisterDto {
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() @Matches(/^\+?[1-9]\d{7,14}$/) phone?: string;
  @IsString() @MinLength(12) password!: string;
  @IsOptional() @IsString() @MinLength(2) displayName?: string;
}

export class LoginDto {
  @IsString() identifier!: string;
  @IsString() @MinLength(1) password!: string;
}

export class RefreshDto { @IsString() @MinLength(20) refreshToken!: string; }
