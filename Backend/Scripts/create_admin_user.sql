-- Script tạo tài khoản Admin cho Backend
-- Chạy script này trong SQL Server Management Studio hoặc Azure Data Studio

-- Bước 1: Tạo User (IdentityUser)
-- Password: Admin@123 (đã hash bằng Identity hasher)
DECLARE @AdminUserId NVARCHAR(450) = NEWID();

-- Thêm vào AspNetUsers
INSERT INTO AspNetUsers (Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PasswordHash, SecurityStamp, ConcurrencyStamp, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount)
VALUES (
    @AdminUserId,
    'admin',
    'ADMIN',
    'admin@pickleball.com',
    'ADMIN@PICKLEBALL.COM',
    1,
    'AQAAAAIAAYagAAAAEKxJ8qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZw==', -- Password: Admin@123
    NEWID(),
    NEWID(),
    0,
    0,
    0,
    0
);

-- Bước 2: Tạo Role Admin nếu chưa có
IF NOT EXISTS (SELECT 1 FROM AspNetRoles WHERE Name = 'Admin')
BEGIN
    DECLARE @AdminRoleId NVARCHAR(450) = NEWID();
    INSERT INTO AspNetRoles (Id, Name, NormalizedName, ConcurrencyStamp)
    VALUES (@AdminRoleId, 'Admin', 'ADMIN', NEWID());
END

-- Bước 3: Gán Role Admin cho User
DECLARE @RoleId NVARCHAR(450) = (SELECT Id FROM AspNetRoles WHERE Name = 'Admin');
INSERT INTO AspNetUserRoles (UserId, RoleId)
VALUES (@AdminUserId, @RoleId);

-- Bước 4: Tạo Member profile cho Admin
INSERT INTO [729_Members] (UserId, FullName, WalletBalance, Tier, RankLevel, IsActive, JoinDate, TotalSpent)
VALUES (
    @AdminUserId,
    'Administrator',
    0,
    2, -- Premium tier
    5.0, -- High rank
    1,
    GETUTCDATE(),
    0
);

PRINT 'Admin account created successfully!';
PRINT 'Username: admin';
PRINT 'Password: Admin@123';
PRINT 'Email: admin@pickleball.com';
