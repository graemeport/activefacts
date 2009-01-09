CREATE TABLE Person (
	-- Person has PersonID,
	PersonID                                int IDENTITY NOT NULL,
	-- Person is called Name,
	Name                                    varchar NOT NULL,
	-- maybe Girl is a subtype of Person and maybe Girlfriend is going out with Boyfriend and Person has PersonID,
	GirlBoyfriendID                         int NULL,
	PRIMARY KEY(PersonID),
	FOREIGN KEY (GirlBoyfriendID) REFERENCES Person (PersonID)
)
GO

CREATE VIEW dbo.GirlInPerson_BoyfriendID (GirlBoyfriendID) WITH SCHEMABINDING AS
	SELECT GirlBoyfriendID FROM dbo.Person
	WHERE	GirlBoyfriendID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_GirlInPersonByGirlBoyfriendID ON dbo.GirlInPerson_BoyfriendID(GirlBoyfriendID)
GO

