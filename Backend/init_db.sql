USE [CLB_Pickleball]
GO

/****** 1. Create Identity Tables ******/

-- AspNetRoles
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[AspNetRoles](
	[Id] [nvarchar](450) NOT NULL,
	[Name] [nvarchar](256) NULL,
	[NormalizedName] [nvarchar](256) NULL,
	[ConcurrencyStamp] [nvarchar](max) NULL,
 CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
)
END
GO

-- AspNetUsers
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[AspNetUsers](
	[Id] [nvarchar](450) NOT NULL,
	[UserName] [nvarchar](256) NULL,
	[NormalizedUserName] [nvarchar](256) NULL,
	[Email] [nvarchar](256) NULL,
	[NormalizedEmail] [nvarchar](256) NULL,
	[EmailConfirmed] [bit] NOT NULL,
	[PasswordHash] [nvarchar](max) NULL,
	[SecurityStamp] [nvarchar](max) NULL,
	[ConcurrencyStamp] [nvarchar](max) NULL,
	[PhoneNumber] [nvarchar](max) NULL,
	[PhoneNumberConfirmed] [bit] NOT NULL,
	[TwoFactorEnabled] [bit] NOT NULL,
	[LockoutEnd] [datetimeoffset](7) NULL,
	[LockoutEnabled] [bit] NOT NULL,
	[AccessFailedCount] [int] NOT NULL,
 CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC)
)
END
GO

-- AspNetUserRoles
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserRoles]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[AspNetUserRoles](
	[UserId] [nvarchar](450) NOT NULL,
	[RoleId] [nvarchar](450) NOT NULL,
 CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),
 CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
 CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
)
END
GO

-- Identity Claims/Logins/Tokens (Simplified for brevity but standard)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserClaims]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[AspNetUserClaims](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](450) NOT NULL,
	[ClaimType] [nvarchar](max) NULL,
	[ClaimValue] [nvarchar](max) NULL,
 CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
)
END
GO

/****** 2. Create Application Tables ******/

-- 729_TransactionCategories
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_TransactionCategories]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_TransactionCategories](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[Type] [int] NOT NULL,
 CONSTRAINT [PK_729_TransactionCategories] PRIMARY KEY CLUSTERED ([Id] ASC)
)
END
GO

-- 729_Courts
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_Courts]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_Courts](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](max) NULL,
	[PricePerHour] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_729_Courts] PRIMARY KEY CLUSTERED ([Id] ASC)
)
END
GO

-- 729_Tournaments
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_Tournaments]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_Tournaments](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[StartDate] [datetime2](7) NOT NULL,
	[EndDate] [datetime2](7) NOT NULL,
	[Format] [int] NOT NULL,
	[EntryFee] [decimal](18, 2) NOT NULL,
	[PrizePool] [decimal](18, 2) NOT NULL,
	[Status] [int] NOT NULL,
	[Settings] [nvarchar](max) NULL,
 CONSTRAINT [PK_729_Tournaments] PRIMARY KEY CLUSTERED ([Id] ASC)
)
END
GO

-- 729_Members
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_Members]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_Members](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FullName] [nvarchar](max) NOT NULL,
	[JoinDate] [datetime2](7) NOT NULL,
	[RankLevel] [float] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UserId] [nvarchar](450) NOT NULL,
	[WalletBalance] [decimal](18, 2) NOT NULL,
	[Tier] [int] NOT NULL,
	[TotalSpent] [decimal](18, 2) NOT NULL,
	[AvatarUrl] [nvarchar](max) NULL,
 CONSTRAINT [PK_729_Members] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_Members_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
)
END
GO

-- 729_RankHistories
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_RankHistories]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_RankHistories](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MemberId] [int] NOT NULL,
	[OldRank] [float] NOT NULL,
	[NewRank] [float] NOT NULL,
	[ChangedDate] [datetime2](7) NOT NULL,
	[Reason] [nvarchar](max) NULL,
	[MatchId] [int] NULL, -- Allow NULL initially
 CONSTRAINT [PK_729_RankHistories] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_RankHistories_729_Members_MemberId] FOREIGN KEY([MemberId]) REFERENCES [dbo].[729_Members] ([Id]) ON DELETE CASCADE
)
END
GO

-- 729_Notifications
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_Notifications]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_Notifications](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ReceiverId] [int] NOT NULL,
	[Title] [nvarchar](max) NULL,
	[Message] [nvarchar](max) NOT NULL,
	[Type] [int] NOT NULL,
	[LinkUrl] [nvarchar](max) NULL,
	[IsRead] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_729_Notifications] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_Notifications_729_Members_ReceiverId] FOREIGN KEY([ReceiverId]) REFERENCES [dbo].[729_Members] ([Id]) ON DELETE CASCADE
)
END
GO

-- 729_News
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_News]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_News](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](max) NOT NULL,
	[Content] [nvarchar](max) NOT NULL,
	[AuthorId] [int] NULL,
	[IsPinned] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[PublishedDate] [datetime2](7) NULL,
	[ImageUrl] [nvarchar](max) NULL,
 CONSTRAINT [PK_729_News] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_News_729_Members_AuthorId] FOREIGN KEY([AuthorId]) REFERENCES [dbo].[729_Members] ([Id])
)
END
GO

-- 729_TournamentParticipants
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_TournamentParticipants]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_TournamentParticipants](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TournamentId] [int] NOT NULL,
	[MemberId] [int] NOT NULL,
	[TeamName] [nvarchar](max) NULL,
	[PaymentStatus] [bit] NOT NULL,
 CONSTRAINT [PK_729_TournamentParticipants] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_TournamentParticipants_729_Members_MemberId] FOREIGN KEY([MemberId]) REFERENCES [dbo].[729_Members] ([Id]) ON DELETE CASCADE,
 CONSTRAINT [FK_729_TournamentParticipants_729_Tournaments_TournamentId] FOREIGN KEY([TournamentId]) REFERENCES [dbo].[729_Tournaments] ([Id]) ON DELETE CASCADE
)
END
GO

-- 729_Matches
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_Matches]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_Matches](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TournamentId] [int] NULL,
	[RoundName] [nvarchar](max) NOT NULL,
	[Date] [datetime2](7) NOT NULL,
	[StartTime] [time](7) NOT NULL,
	[Team1_Player1Id] [int] NULL,
	[Team1_Player2Id] [int] NULL,
	[Team2_Player1Id] [int] NULL,
	[Team2_Player2Id] [int] NULL,
	[Score1] [int] NOT NULL,
	[Score2] [int] NOT NULL,
	[Details] [nvarchar](max) NULL,
	[WinningSide] [int] NOT NULL,
	[IsRanked] [bit] NOT NULL,
	[Status] [int] NOT NULL,
 CONSTRAINT [PK_729_Matches] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_Matches_729_Tournaments_TournamentId] FOREIGN KEY([TournamentId]) REFERENCES [dbo].[729_Tournaments] ([Id])
)
END
GO

-- 729_WalletTransactions
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_WalletTransactions]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_WalletTransactions](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MemberId] [int] NOT NULL,
	[Amount] [decimal](18, 2) NOT NULL,
	[Type] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[RelatedId] [nvarchar](max) NULL,
	[Description] [nvarchar](max) NULL,
	[ProofImageUrl] [nvarchar](max) NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_729_WalletTransactions] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_WalletTransactions_729_Members_MemberId] FOREIGN KEY([MemberId]) REFERENCES [dbo].[729_Members] ([Id]) ON DELETE CASCADE
)
END
GO

-- 729_Bookings
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[729_Bookings]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[729_Bookings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourtId] [int] NOT NULL,
	[MemberId] [int] NOT NULL,
	[StartTime] [datetime2](7) NOT NULL,
	[EndTime] [datetime2](7) NOT NULL,
	[TotalPrice] [decimal](18, 2) NOT NULL,
	[TransactionId] [int] NULL,
	[IsRecurring] [bit] NOT NULL,
	[RecurrenceRule] [nvarchar](max) NULL,
	[ParentBookingId] [int] NULL,
	[Status] [int] NOT NULL,
 CONSTRAINT [PK_729_Bookings] PRIMARY KEY CLUSTERED ([Id] ASC),
 CONSTRAINT [FK_729_Bookings_729_Courts_CourtId] FOREIGN KEY([CourtId]) REFERENCES [dbo].[729_Courts] ([Id]) ON DELETE CASCADE,
 CONSTRAINT [FK_729_Bookings_729_Members_MemberId] FOREIGN KEY([MemberId]) REFERENCES [dbo].[729_Members] ([Id]) ON DELETE CASCADE,
 CONSTRAINT [FK_729_Bookings_729_WalletTransactions_TransactionId] FOREIGN KEY([TransactionId]) REFERENCES [dbo].[729_WalletTransactions] ([Id])
)
END
GO

/****** 3. INSERT SAMPLE DATA ******/

-- Identity Variables
DECLARE @AdminId NVARCHAR(450) = NEWID();
DECLARE @UserId NVARCHAR(450) = NEWID();
DECLARE @RoleId_Admin NVARCHAR(450) = NEWID();
DECLARE @RoleId_User NVARCHAR(450) = NEWID();
DECLARE @CurrentTime DATETIME = GETUTCDATE();

-- Insert Roles
INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName], [ConcurrencyStamp]) VALUES 
(@RoleId_Admin, N'Admin', N'ADMIN', NEWID()),
(@RoleId_User, N'User', N'USER', NEWID());

-- Insert Users (Password hashes are placeholders 'Password123!')
-- Admin: tungnt
INSERT INTO [dbo].[AspNetUsers] ([Id], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumber], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount]) VALUES 
(@AdminId, N'tungnt', N'TUNGNT', N'tungnt@example.com', N'TUNGNT@EXAMPLE.COM', 1, N'AQAAAAIAAYagAAAAEP0wPHq...', N'SECURITY_STAMP_1', NEWID(), N'0909000001', 1, 0, 1, 0);

-- User: user01
INSERT INTO [dbo].[AspNetUsers] ([Id], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumber], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount]) VALUES 
(@UserId, N'user01', N'USER01', N'user01@example.com', N'USER01@EXAMPLE.COM', 1, N'AQAAAAIAAYagAAAAEP0wPHq...', N'SECURITY_STAMP_2', NEWID(), N'0909000002', 1, 0, 1, 0);

-- Assign Roles
INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES 
(@AdminId, @RoleId_Admin),
(@UserId, @RoleId_User);

-- Insert Members
-- Admin Member (Rank 100, Diamond)
INSERT INTO [dbo].[729_Members] ([FullName], [JoinDate], [RankLevel], [IsActive], [UserId], [WalletBalance], [Tier], [TotalSpent], [AvatarUrl]) VALUES 
(N'Nguyen Thanh Tung', @CurrentTime, 100, 1, @AdminId, 10000000, 3, 0, N'https://example.com/admin.jpg');
DECLARE @MemberAdminId INT = SCOPE_IDENTITY();

-- User Member (Rank 10, Standard)
INSERT INTO [dbo].[729_Members] ([FullName], [JoinDate], [RankLevel], [IsActive], [UserId], [WalletBalance], [Tier], [TotalSpent], [AvatarUrl]) VALUES 
(N'Nguyen Van B', @CurrentTime, 10, 1, @UserId, 500000, 0, 0, N'https://example.com/user.jpg');
DECLARE @MemberUserId INT = SCOPE_IDENTITY();

-- Insert Courts
INSERT INTO [dbo].[729_Courts] ([Name], [IsActive], [Description], [PricePerHour]) VALUES 
(N'San 1', 1, N'San tieu chuan ngoai troi', 50000),
(N'San VIP', 1, N'San VIP co mai che va may lanh', 80000);
DECLARE @Court1Id INT = (SELECT TOP 1 Id FROM [dbo].[729_Courts] WHERE Name = N'San 1');
DECLARE @Court2Id INT = (SELECT TOP 1 Id FROM [dbo].[729_Courts] WHERE Name = N'San VIP');

-- Insert Transaction Categories
INSERT INTO [dbo].[729_TransactionCategories] ([Name], [Type]) VALUES 
(N'Nap tien vao vi', 0), -- 0: Income
(N'Thanh toan san', 1); -- 1: Expense

-- Insert Wallet Transactions
-- Deposit for Admin
INSERT INTO [dbo].[729_WalletTransactions] ([MemberId], [Amount], [Type], [Status], [RelatedId], [Description], [ProofImageUrl], [CreatedDate]) VALUES 
(@MemberAdminId, 10000000, 0, 1, NULL, N'Nap lan dau', N'http://proof.com/1.jpg', @CurrentTime);
DECLARE @Trans1Id INT = SCOPE_IDENTITY();

-- Payment for User (booking)
INSERT INTO [dbo].[729_WalletTransactions] ([MemberId], [Amount], [Type], [Status], [RelatedId], [Description], [ProofImageUrl], [CreatedDate]) VALUES 
(@MemberUserId, 100000, 2, 1, NULL, N'Thanh toan san', NULL, @CurrentTime);
DECLARE @Trans2Id INT = SCOPE_IDENTITY();

-- Insert Bookings
-- Booking 1: Admin book San VIP
INSERT INTO [dbo].[729_Bookings] ([CourtId], [MemberId], [StartTime], [EndTime], [TotalPrice], [TransactionId], [IsRecurring], [RecurrenceRule], [ParentBookingId], [Status]) VALUES 
(@Court2Id, @MemberAdminId, DATEADD(hour, 1, @CurrentTime), DATEADD(hour, 3, @CurrentTime), 160000, NULL, 0, NULL, NULL, 1); -- 1: Paid/Confirmed

-- Booking 2: User book San 1
INSERT INTO [dbo].[729_Bookings] ([CourtId], [MemberId], [StartTime], [EndTime], [TotalPrice], [TransactionId], [IsRecurring], [RecurrenceRule], [ParentBookingId], [Status]) VALUES 
(@Court1Id, @MemberUserId, DATEADD(day, 1, @CurrentTime), DATEADD(day, 1, DATEADD(hour, 2, @CurrentTime)), 100000, @Trans2Id, 0, NULL, NULL, 1);

-- Insert Tournaments
INSERT INTO [dbo].[729_Tournaments] ([Name], [StartDate], [EndDate], [Format], [EntryFee], [PrizePool], [Status], [Settings]) VALUES 
(N'Giai Mua Xuan Open', DATEADD(month, 1, @CurrentTime), DATEADD(month, 1, DATEADD(day, 2, @CurrentTime)), 0, 200000, 5000000, 0, N'{"Groups": 4}'), -- 0: Open
(N'Giai Noi Bo', DATEADD(day, 7, @CurrentTime), DATEADD(day, 8, @CurrentTime), 1, 50000, 1000000, 1, N'{}'); -- 1: Registering
DECLARE @Tour1Id INT = (SELECT TOP 1 Id FROM [dbo].[729_Tournaments] WHERE Name = N'Giai Mua Xuan Open');
DECLARE @Tour2Id INT = (SELECT TOP 1 Id FROM [dbo].[729_Tournaments] WHERE Name = N'Giai Noi Bo');

-- Insert Tournament Participants
INSERT INTO [dbo].[729_TournamentParticipants] ([TournamentId], [MemberId], [TeamName], [PaymentStatus]) VALUES 
(@Tour1Id, @MemberAdminId, N'Team Admin', 1),
(@Tour1Id, @MemberUserId, N'Team User', 1);

-- Insert Matches (Fake participants IDs as Member IDs for simplicity if allowed, or leave NULL if not strictly enforced)
INSERT INTO [dbo].[729_Matches] ([TournamentId], [RoundName], [Date], [StartTime], [Team1_Player1Id], [Team1_Player2Id], [Team2_Player1Id], [Team2_Player2Id], [Score1], [Score2], [Details], [WinningSide], [IsRanked], [Status]) VALUES 
(@Tour1Id, N'Vong Bang', DATEADD(month, 1, @CurrentTime), '08:00:00', @MemberAdminId, NULL, @MemberUserId, NULL, 11, 5, N'11-5, 11-2', 1, 1, 2), -- 1: Team1 Win, 2: Finished
(@Tour1Id, N'Vong Bang', DATEADD(month, 1, @CurrentTime), '09:00:00', @MemberUserId, NULL, @MemberAdminId, NULL, 0, 0, NULL, 0, 1, 0); -- 0: Scheduled

-- Insert News
INSERT INTO [dbo].[729_News] ([Title], [Content], [AuthorId], [IsPinned], [IsActive], [CreatedDate], [PublishedDate], [ImageUrl]) VALUES 
(N'Thong bao khai mac giai Mua Xuan', N'Giai se bat dau vao thang toi...', @MemberAdminId, 1, 1, @CurrentTime, @CurrentTime, N'http://news.com/1.jpg'),
(N'Uu dai thue san', N'Giam gia 50% cho hoi vien moi...', @MemberAdminId, 0, 1, @CurrentTime, @CurrentTime, N'http://news.com/2.jpg');

-- Insert Notifications
INSERT INTO [dbo].[729_Notifications] ([ReceiverId], [Title], [Message], [Type], [LinkUrl], [IsRead], [CreatedDate]) VALUES 
(@MemberUserId, N'Chao mung ban', N'Chao mung ban gia nhap CLB Pickleball', 0, NULL, 0, @CurrentTime),
(@MemberAdminId, N'He thong', N'He thong da duoc khoi tao thanh cong', 0, NULL, 1, @CurrentTime);

-- Insert Rank History
INSERT INTO [dbo].[729_RankHistories] ([MemberId], [OldRank], [NewRank], [ChangedDate], [Reason], [MatchId]) VALUES 
(@MemberAdminId, 0, 100, @CurrentTime, N'Initial Rank', NULL),
(@MemberUserId, 0, 10, @CurrentTime, N'Placement Match', NULL);

GO
