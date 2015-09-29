---
layout: post
title: "Test DB reset with Respawn"
description: "When doing testing against DB it is important to reset it to initial state. I am using Entity Framework for SQL DB access and it provides mechanism to recreate DB each time, but it is slow and sometimes fails because of open DB connections. Much easier is to delete everything from tables and Respawn is great too which helps to do it."
category: [Testing]
tags: [Testing]
date: 2015-09-29
visible: true
---

<p class="lead">
When doing testing against DB it is important to reset it to the initial state. I am using Entity Framework for SQL DB access and it provides a mechanism to recreate DB each time, but it is slow and sometimes fails because of open DB connections. Much easier is to delete everything from tables and Respawn is great too which helps to do it.
</p>

[Respawn](https://github.com/jbogard/Respawn) is created by [Jimmy Bogard](https://lostechies.com/jimmybogard/). You can find documentation on tool's [Github page](https://github.com/jbogard/Respawn).

For my purpose, I needed cleaning all my tables in test DB, but sometimes I also required to recreate the whole DB when schema had changed. I am also writing my DB tests so that those do not depend on other tests and that those do not conflict with data already in tables. Because of that I can reset DB only once when running tests.

As I am using [xUnit.net](http://xunit.github.io/), I can use [Collection Fixture](http://xunit.github.io/docs/shared-context.html#collection-fixture) which will trigger DB reset for my DB tests. It will reset DB once per test run.

First define fixture which resets DB. It is a simple C# class with default constructor where reset should happen. Create _Checkpoint_ as a static field and optionally initialize with tables you want to skip, or schemas to ignore and other settings. Then in constructor call _Reset_ method with the connection string.

    public class DbFixture
    {
        private static readonly Checkpoint Checkpoint = new Checkpoint();

        public DbFixture()
        {
            var connectionString = ConfigurationManager
                                        .ConnectionStrings["AppConnectionString"]
                                        .ConnectionString;
            Checkpoint.Reset(connectionString);
        }
    }

Now define fixture collection.

    [CollectionDefinition("DbCollection")]
    public class DbFixtureCollection : ICollectionFixture<DbFixture> { }

And use this collection for DB tests by decorating test class with _Collection_ attribute. _Collection_ attribute's name should match _CollectionDefinition_ attribute's name on fixture collection class.

    [Collection("DbCollection")]
    public class EntityRepositoryTests
    {
        [Fact]
        public void getById_returns_existing_entity()
        {
            ...
        }
    }

Now DB will be reset once for all tests in same fixture collection before each test run.

Next task is to re-create database when needed. To achieve that first I will create a special attribute for the test which will run only in debug mode. Jimmy Bogard wrote an article how to create such [RunnableInDebugOnlyAttribute](https://lostechies.com/jimmybogard/2013/06/20/run-tests-explicitly-in-xunit-net/).

    public class RunnableInDebugOnlyAttribute : FactAttribute
    {
        public RunnableInDebugOnlyAttribute()
        {
            if (!Debugger.IsAttached)
            {
                Skip = "Only running in interactive mode.";
            }
        }
    }

Then create a test which recreates DB. Use _Entity Framework's_ _DropCreateDatabaseAlways_ initializer in the test.

    public class DatabaseSeedingInitializer 
        : DropCreateDatabaseAlways<WebshopDbContext> { }

    public class SchemaCreationTest
    {
        [RunnableInDebugOnly]
        public void Wipe_Database()
        {
            Database.SetInitializer(new DatabaseSeedingInitializer());
            using (var context = new AppDbContext())
            {
                context.Database.Initialize(true);
            }
        }
    }

Testing against database might be hard, but if you have good tools, then it is not much harder than unit testing.