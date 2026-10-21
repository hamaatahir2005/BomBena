import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import * as Joi from 'joi';
import { AuthModule } from './auth/auth.module';
import { AppController } from './app.controller';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validationSchema: Joi.object({
      NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
      API_PORT: Joi.number().port().default(3000), DATABASE_URL: Joi.string().required(),
      JWT_ACCESS_SECRET: Joi.string().min(32).required(), JWT_REFRESH_SECRET: Joi.string().min(32).required(),
      JWT_ACCESS_TTL: Joi.string().default('15m'), JWT_REFRESH_TTL_DAYS: Joi.number().integer().min(1).default(30),
    }) }),
    PrismaModule, AuthModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
