-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('CUSTOMER', 'RIDER', 'RESTAURANT_ADMIN', 'RESTAURANT_STAFF', 'PLATFORM_ADMIN', 'PLATFORM_SUPPORT');

-- CreateEnum
CREATE TYPE "AccountStatus" AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'DELETED');

-- CreateEnum
CREATE TYPE "RestaurantStatus" AS ENUM ('PENDING_APPROVAL', 'ACTIVE', 'REJECTED', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "RiderApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING_PAYMENT', 'PLACED', 'RESTAURANT_ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'RIDER_ASSIGNED', 'PICKED_UP', 'ON_THE_WAY', 'DELIVERED', 'CANCELLED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'AUTHORIZED', 'PAID', 'FAILED', 'PARTIALLY_REFUNDED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH_ON_DELIVERY', 'ONLINE');

-- CreateEnum
CREATE TYPE "DeliveryStatus" AS ENUM ('OFFERED', 'ASSIGNED', 'PICKED_UP', 'DELIVERING', 'DELIVERED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "LedgerEntryType" AS ENUM ('ORDER_CHARGE', 'RESTAURANT_COMMISSION', 'RIDER_EARNING', 'DELIVERY_FEE', 'REFUND', 'CASH_COLLECTION', 'PAYOUT', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "SupportStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED');

-- CreateEnum
CREATE TYPE "CouponType" AS ENUM ('FIXED_AMOUNT', 'PERCENTAGE', 'FREE_DELIVERY');

-- CreateEnum
CREATE TYPE "SettlementStatus" AS ENUM ('PENDING', 'PROCESSING', 'PAID', 'FAILED');

-- CreateEnum
CREATE TYPE "NotificationChannel" AS ENUM ('PUSH', 'EMAIL', 'SMS', 'IN_APP');

-- CreateEnum
CREATE TYPE "NotificationStatus" AS ENUM ('QUEUED', 'SENT', 'FAILED', 'READ');

-- CreateEnum
CREATE TYPE "DiscountType" AS ENUM ('FIXED_AMOUNT', 'PERCENTAGE');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" VARCHAR(320),
    "phone" VARCHAR(32),
    "password_hash" VARCHAR(255),
    "status" "AccountStatus" NOT NULL DEFAULT 'PENDING',
    "email_verified_at" TIMESTAMP(3),
    "phone_verified_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "roles" "UserRole"[],

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token_hash" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "revoked_at" TIMESTAMP(3),
    "replaced_by" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customer_profiles" (
    "user_id" UUID NOT NULL,
    "display_name" VARCHAR(120),
    "preferred_language" VARCHAR(8) NOT NULL DEFAULT 'ckb',
    "avatar_key" VARCHAR(512),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "customer_profiles_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "rider_profiles" (
    "user_id" UUID NOT NULL,
    "approval_status" "RiderApprovalStatus" NOT NULL DEFAULT 'PENDING',
    "vehicle_type" VARCHAR(40),
    "document_keys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "approved_at" TIMESTAMP(3),
    "available" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rider_profiles_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "restaurants" (
    "id" UUID NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "slug" VARCHAR(180) NOT NULL,
    "description" TEXT,
    "status" "RestaurantStatus" NOT NULL DEFAULT 'PENDING_APPROVAL',
    "commission_bps" INTEGER NOT NULL DEFAULT 1500,
    "logo_key" VARCHAR(512),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "restaurants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "restaurant_branches" (
    "id" UUID NOT NULL,
    "restaurant_id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "phone" VARCHAR(32),
    "address" TEXT NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "opening_hours" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "restaurant_branches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "restaurant_staff" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "restaurant_id" UUID NOT NULL,
    "role" VARCHAR(40) NOT NULL DEFAULT 'MANAGER',
    "permissions" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "restaurant_staff_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "addresses" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "label" VARCHAR(60) NOT NULL,
    "address_line" TEXT NOT NULL,
    "city" VARCHAR(100) NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "delivery_note" TEXT,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "service_zones" (
    "id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "city" VARCHAR(100) NOT NULL,
    "boundary_geo_json" JSONB NOT NULL,
    "base_fee_minor" INTEGER NOT NULL,
    "per_km_fee_minor" INTEGER NOT NULL DEFAULT 0,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "service_zones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "menu_categories" (
    "id" UUID NOT NULL,
    "restaurant_id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "menu_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "menu_items" (
    "id" UUID NOT NULL,
    "restaurant_id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "description" TEXT,
    "image_key" VARCHAR(512),
    "price_minor" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "menu_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "menu_item_variants" (
    "id" UUID NOT NULL,
    "menu_item_id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "price_minor" INTEGER NOT NULL,

    CONSTRAINT "menu_item_variants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "menu_item_addons" (
    "id" UUID NOT NULL,
    "menu_item_id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "price_minor" INTEGER NOT NULL,

    CONSTRAINT "menu_item_addons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favorites" (
    "customer_id" UUID NOT NULL,
    "restaurant_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favorites_pkey" PRIMARY KEY ("customer_id","restaurant_id")
);

-- CreateTable
CREATE TABLE "carts" (
    "id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "carts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cart_items" (
    "id" UUID NOT NULL,
    "cart_id" UUID NOT NULL,
    "menu_item_id" UUID NOT NULL,
    "quantity" INTEGER NOT NULL,
    "selections" JSONB NOT NULL DEFAULT '[]',

    CONSTRAINT "cart_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coupons" (
    "id" UUID NOT NULL,
    "code" VARCHAR(40) NOT NULL,
    "type" "CouponType" NOT NULL,
    "value" INTEGER NOT NULL,
    "max_discount_minor" INTEGER,
    "starts_at" TIMESTAMP(3) NOT NULL,
    "ends_at" TIMESTAMP(3) NOT NULL,
    "usage_limit" INTEGER,
    "usage_count" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "coupons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "promotions" (
    "id" UUID NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "description" TEXT,
    "image_key" TEXT,
    "starts_at" TIMESTAMP(3) NOT NULL,
    "ends_at" TIMESTAMP(3) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "promotions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" UUID NOT NULL,
    "order_number" VARCHAR(32) NOT NULL,
    "customer_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "address_id" UUID NOT NULL,
    "coupon_id" UUID,
    "status" "OrderStatus" NOT NULL DEFAULT 'PLACED',
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "subtotal_minor" INTEGER NOT NULL,
    "delivery_fee_minor" INTEGER NOT NULL,
    "discount_minor" INTEGER NOT NULL DEFAULT 0,
    "tax_minor" INTEGER NOT NULL DEFAULT 0,
    "total_minor" INTEGER NOT NULL,
    "commission_minor" INTEGER NOT NULL DEFAULT 0,
    "delivery_address_snapshot" JSONB NOT NULL,
    "idempotency_key" VARCHAR(128) NOT NULL,
    "customer_note" TEXT,
    "cancellation_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "menu_item_id" UUID NOT NULL,
    "item_name_snapshot" VARCHAR(160) NOT NULL,
    "unit_price_minor" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "line_total_minor" INTEGER NOT NULL,
    "options_snapshot" JSONB NOT NULL DEFAULT '[]',

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_item_options" (
    "id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "option_name_snapshot" VARCHAR(120) NOT NULL,
    "price_minor_snapshot" INTEGER NOT NULL,

    CONSTRAINT "order_item_options_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_status_history" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "from_status" "OrderStatus",
    "to_status" "OrderStatus" NOT NULL,
    "actor_user_id" UUID,
    "note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_status_history_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deliveries" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "rider_id" UUID,
    "status" "DeliveryStatus" NOT NULL DEFAULT 'OFFERED',
    "offer_expires_at" TIMESTAMP(3),
    "pickup_pin_hash" VARCHAR(255),
    "delivery_pin_hash" VARCHAR(255),
    "assigned_at" TIMESTAMP(3),
    "picked_up_at" TIMESTAMP(3),
    "delivered_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "deliveries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rider_locations" (
    "id" UUID NOT NULL,
    "rider_id" UUID NOT NULL,
    "delivery_id" UUID NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "recorded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rider_locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "amount_minor" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "provider" VARCHAR(80),
    "provider_reference" VARCHAR(160),
    "paid_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_attempts" (
    "id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "provider" VARCHAR(80) NOT NULL,
    "provider_reference" VARCHAR(160),
    "idempotency_key" VARCHAR(128) NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "request_metadata" JSONB,
    "response_metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payment_attempts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refunds" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "amount_minor" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "reason" TEXT NOT NULL,
    "status" "SettlementStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refunds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "restaurant_reviews" (
    "id" UUID NOT NULL,
    "restaurant_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "restaurant_reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rider_earnings" (
    "id" UUID NOT NULL,
    "rider_id" UUID NOT NULL,
    "delivery_id" UUID NOT NULL,
    "amount_minor" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rider_earnings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "restaurant_settlements" (
    "id" UUID NOT NULL,
    "restaurant_id" UUID NOT NULL,
    "period_start" TIMESTAMP(3) NOT NULL,
    "period_end" TIMESTAMP(3) NOT NULL,
    "gross_minor" INTEGER NOT NULL,
    "commission_minor" INTEGER NOT NULL,
    "net_minor" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "status" "SettlementStatus" NOT NULL DEFAULT 'PENDING',
    "paid_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "restaurant_settlements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "financial_ledger_entries" (
    "id" UUID NOT NULL,
    "order_id" UUID,
    "entry_type" "LedgerEntryType" NOT NULL,
    "amount_minor" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "reference" VARCHAR(160),
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "financial_ledger_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cash_collections" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "rider_id" UUID NOT NULL,
    "amount_minor" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'IQD',
    "collected_at" TIMESTAMP(3),
    "settled_at" TIMESTAMP(3),

    CONSTRAINT "cash_collections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "channel" "NotificationChannel" NOT NULL,
    "status" "NotificationStatus" NOT NULL DEFAULT 'QUEUED',
    "title" VARCHAR(160) NOT NULL,
    "body" TEXT NOT NULL,
    "payload" JSONB NOT NULL DEFAULT '{}',
    "sent_at" TIMESTAMP(3),
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "support_tickets" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "subject" VARCHAR(180) NOT NULL,
    "message" TEXT NOT NULL,
    "status" "SupportStatus" NOT NULL DEFAULT 'OPEN',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "support_tickets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "actor_user_id" UUID,
    "action" VARCHAR(120) NOT NULL,
    "entity_type" VARCHAR(80) NOT NULL,
    "entity_id" VARCHAR(80) NOT NULL,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "ip_address" VARCHAR(64),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_settings" (
    "key" VARCHAR(120) NOT NULL,
    "value" JSONB NOT NULL,
    "description" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "system_settings_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE INDEX "users_status_created_at_idx" ON "users"("status", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_expires_at_idx" ON "refresh_tokens"("user_id", "expires_at");

-- CreateIndex
CREATE INDEX "rider_profiles_approval_status_available_idx" ON "rider_profiles"("approval_status", "available");

-- CreateIndex
CREATE UNIQUE INDEX "restaurants_slug_key" ON "restaurants"("slug");

-- CreateIndex
CREATE INDEX "restaurants_status_name_idx" ON "restaurants"("status", "name");

-- CreateIndex
CREATE INDEX "restaurant_branches_restaurant_id_is_active_idx" ON "restaurant_branches"("restaurant_id", "is_active");

-- CreateIndex
CREATE INDEX "restaurant_staff_restaurant_id_idx" ON "restaurant_staff"("restaurant_id");

-- CreateIndex
CREATE UNIQUE INDEX "restaurant_staff_user_id_restaurant_id_key" ON "restaurant_staff"("user_id", "restaurant_id");

-- CreateIndex
CREATE INDEX "addresses_user_id_is_default_idx" ON "addresses"("user_id", "is_default");

-- CreateIndex
CREATE UNIQUE INDEX "menu_categories_restaurant_id_name_key" ON "menu_categories"("restaurant_id", "name");

-- CreateIndex
CREATE INDEX "menu_items_restaurant_id_is_available_idx" ON "menu_items"("restaurant_id", "is_available");

-- CreateIndex
CREATE UNIQUE INDEX "carts_customer_id_key" ON "carts"("customer_id");

-- CreateIndex
CREATE INDEX "cart_items_cart_id_idx" ON "cart_items"("cart_id");

-- CreateIndex
CREATE UNIQUE INDEX "coupons_code_key" ON "coupons"("code");

-- CreateIndex
CREATE INDEX "promotions_is_active_starts_at_ends_at_idx" ON "promotions"("is_active", "starts_at", "ends_at");

-- CreateIndex
CREATE UNIQUE INDEX "orders_order_number_key" ON "orders"("order_number");

-- CreateIndex
CREATE UNIQUE INDEX "orders_idempotency_key_key" ON "orders"("idempotency_key");

-- CreateIndex
CREATE INDEX "orders_customer_id_created_at_idx" ON "orders"("customer_id", "created_at");

-- CreateIndex
CREATE INDEX "orders_branch_id_status_created_at_idx" ON "orders"("branch_id", "status", "created_at");

-- CreateIndex
CREATE INDEX "orders_status_created_at_idx" ON "orders"("status", "created_at");

-- CreateIndex
CREATE INDEX "order_items_order_id_idx" ON "order_items"("order_id");

-- CreateIndex
CREATE INDEX "order_status_history_order_id_created_at_idx" ON "order_status_history"("order_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "deliveries_order_id_key" ON "deliveries"("order_id");

-- CreateIndex
CREATE INDEX "deliveries_rider_id_status_idx" ON "deliveries"("rider_id", "status");

-- CreateIndex
CREATE INDEX "rider_locations_delivery_id_recorded_at_idx" ON "rider_locations"("delivery_id", "recorded_at");

-- CreateIndex
CREATE INDEX "rider_locations_rider_id_recorded_at_idx" ON "rider_locations"("rider_id", "recorded_at");

-- CreateIndex
CREATE UNIQUE INDEX "payments_order_id_key" ON "payments"("order_id");

-- CreateIndex
CREATE INDEX "payments_status_created_at_idx" ON "payments"("status", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "payment_attempts_idempotency_key_key" ON "payment_attempts"("idempotency_key");

-- CreateIndex
CREATE INDEX "payment_attempts_payment_id_created_at_idx" ON "payment_attempts"("payment_id", "created_at");

-- CreateIndex
CREATE INDEX "refunds_order_id_created_at_idx" ON "refunds"("order_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "restaurant_reviews_order_id_key" ON "restaurant_reviews"("order_id");

-- CreateIndex
CREATE INDEX "restaurant_reviews_restaurant_id_created_at_idx" ON "restaurant_reviews"("restaurant_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "rider_earnings_delivery_id_key" ON "rider_earnings"("delivery_id");

-- CreateIndex
CREATE INDEX "rider_earnings_rider_id_created_at_idx" ON "rider_earnings"("rider_id", "created_at");

-- CreateIndex
CREATE INDEX "restaurant_settlements_restaurant_id_status_period_start_idx" ON "restaurant_settlements"("restaurant_id", "status", "period_start");

-- CreateIndex
CREATE INDEX "financial_ledger_entries_entry_type_created_at_idx" ON "financial_ledger_entries"("entry_type", "created_at");

-- CreateIndex
CREATE INDEX "financial_ledger_entries_order_id_idx" ON "financial_ledger_entries"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "cash_collections_order_id_key" ON "cash_collections"("order_id");

-- CreateIndex
CREATE INDEX "cash_collections_rider_id_settled_at_idx" ON "cash_collections"("rider_id", "settled_at");

-- CreateIndex
CREATE INDEX "notifications_user_id_status_created_at_idx" ON "notifications"("user_id", "status", "created_at");

-- CreateIndex
CREATE INDEX "support_tickets_status_created_at_idx" ON "support_tickets"("status", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_created_at_idx" ON "audit_logs"("entity_type", "entity_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_actor_user_id_created_at_idx" ON "audit_logs"("actor_user_id", "created_at");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_profiles" ADD CONSTRAINT "customer_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rider_profiles" ADD CONSTRAINT "rider_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_branches" ADD CONSTRAINT "restaurant_branches_restaurant_id_fkey" FOREIGN KEY ("restaurant_id") REFERENCES "restaurants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_staff" ADD CONSTRAINT "restaurant_staff_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_staff" ADD CONSTRAINT "restaurant_staff_restaurant_id_fkey" FOREIGN KEY ("restaurant_id") REFERENCES "restaurants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "menu_categories" ADD CONSTRAINT "menu_categories_restaurant_id_fkey" FOREIGN KEY ("restaurant_id") REFERENCES "restaurants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "menu_items" ADD CONSTRAINT "menu_items_restaurant_id_fkey" FOREIGN KEY ("restaurant_id") REFERENCES "restaurants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "menu_items" ADD CONSTRAINT "menu_items_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "menu_categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "menu_item_variants" ADD CONSTRAINT "menu_item_variants_menu_item_id_fkey" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "menu_item_addons" ADD CONSTRAINT "menu_item_addons_menu_item_id_fkey" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customer_profiles"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_restaurant_id_fkey" FOREIGN KEY ("restaurant_id") REFERENCES "restaurants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "carts" ADD CONSTRAINT "carts_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customer_profiles"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_cart_id_fkey" FOREIGN KEY ("cart_id") REFERENCES "carts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_menu_item_id_fkey" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "restaurant_branches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_address_id_fkey" FOREIGN KEY ("address_id") REFERENCES "addresses"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_coupon_id_fkey" FOREIGN KEY ("coupon_id") REFERENCES "coupons"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_menu_item_id_fkey" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_item_options" ADD CONSTRAINT "order_item_options_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_status_history" ADD CONSTRAINT "order_status_history_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deliveries" ADD CONSTRAINT "deliveries_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deliveries" ADD CONSTRAINT "deliveries_rider_id_fkey" FOREIGN KEY ("rider_id") REFERENCES "rider_profiles"("user_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rider_locations" ADD CONSTRAINT "rider_locations_rider_id_fkey" FOREIGN KEY ("rider_id") REFERENCES "rider_profiles"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rider_locations" ADD CONSTRAINT "rider_locations_delivery_id_fkey" FOREIGN KEY ("delivery_id") REFERENCES "deliveries"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_attempts" ADD CONSTRAINT "payment_attempts_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_reviews" ADD CONSTRAINT "restaurant_reviews_restaurant_id_fkey" FOREIGN KEY ("restaurant_id") REFERENCES "restaurants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_reviews" ADD CONSTRAINT "restaurant_reviews_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_reviews" ADD CONSTRAINT "restaurant_reviews_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rider_earnings" ADD CONSTRAINT "rider_earnings_rider_id_fkey" FOREIGN KEY ("rider_id") REFERENCES "rider_profiles"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rider_earnings" ADD CONSTRAINT "rider_earnings_delivery_id_fkey" FOREIGN KEY ("delivery_id") REFERENCES "deliveries"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_settlements" ADD CONSTRAINT "restaurant_settlements_restaurant_id_fkey" FOREIGN KEY ("restaurant_id") REFERENCES "restaurants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "financial_ledger_entries" ADD CONSTRAINT "financial_ledger_entries_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_collections" ADD CONSTRAINT "cash_collections_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_collections" ADD CONSTRAINT "cash_collections_rider_id_fkey" FOREIGN KEY ("rider_id") REFERENCES "rider_profiles"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_tickets" ADD CONSTRAINT "support_tickets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
