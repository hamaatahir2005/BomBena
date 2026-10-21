import { PrismaClient, UserRole, AccountStatus } from '@prisma/client';

const prisma = new PrismaClient();
async function main() {
  await prisma.systemSetting.upsert({ where: { key: 'default_currency' }, update: {}, create: { key: 'default_currency', value: 'IQD', description: 'Default platform currency' } });
  await prisma.systemSetting.upsert({ where: { key: 'rider_location_retention_hours' }, update: {}, create: { key: 'rider_location_retention_hours', value: 72, description: 'Maximum retention for delivery location samples' } });
  // No hardcoded login accounts are seeded. Create identities through the registration flow.
  console.info(`Seeded base settings; role model supports ${Object.values(UserRole).join(', ')} (${AccountStatus.ACTIVE} accounts).`);
}
main().finally(() => prisma.$disconnect());
