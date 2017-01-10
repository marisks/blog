---
layout: post
title: "Entity Framework: Soft Delete and automatic Created, Modified dates"
description: "Convention based soft delete and created and modified date setting makes your code much simpler. Configuring Entity Framework to do it is a bit complicated, but possible."
category:
tags: [.NET,EF,Entity Framework]
date: 2016-02-27
visible: true
---

When working with a database, quite often it is useful to implement soft-delete of records. It simplifies related record management and also preserves some history. It is also common to have Created and Modified dates on the record. While it is possible to do soft delete and setting Created, Modified dates manually, it is error prone. Entity Framework provides an API to do it silently.

When I started to look for the solution I found an article by Rakesh Babu Paruchuri: [Soft Deleting Entities Cleanly Using Entity Framework 6 Interceptors](http://www.codeguru.com/csharp/csharp/soft-deleting-entities-cleanly-using-entity-framework-6-interceptors.html). He uses an attribute to decorate entities with and set the name of _IsDeleted_ column name. I do not like this approach because you duplicate your code - define _IsDeleted_ property on the entity and also set _SoftDelete_ attribute which defines which property use for soft delete. It is simpler, more consistent and less error prone to just "hardcode" the name of the property or allow it to be configured globally.

# Soft Delete

My solution to an issue is almost same as done by Rakesh, but I am using "hardcoded" field name - _IsDeleted_. This way I have a consistent field name all over my application.

```
public class SoftDeleteInterceptor : IDbCommandTreeInterceptor
{
    public const string IsDeletedColumnName = "IsDeleted";

    public void TreeCreated(DbCommandTreeInterceptionContext interceptionContext)
    {
        if (interceptionContext.OriginalResult.DataSpace != DataSpace.SSpace)
        {
            return;
        }

        var queryCommand = interceptionContext.Result as DbQueryCommandTree;
        if (queryCommand != null)
        {
            interceptionContext.Result = HandleQueryCommand(queryCommand);
        }

        var deleteCommand = interceptionContext.OriginalResult as DbDeleteCommandTree;
        if (deleteCommand != null)
        {
            interceptionContext.Result = HandleDeleteCommand(deleteCommand);
        }
    }

    // ...
}
```

First, create a class which implements _IDbCommandTreeInterceptor_ interface's method _TreeCreated_. At this step (tree created), _Entity Framework's_ full command is already built and it is possible to modify it before execution. _TreeCreated_ has _DbCommandTreeInterceptionContext_ parameter which has _Result_ property with full command expression tree of different types - insert, delete, query, update.

For soft delete, I have to handle two cases - deletion of record and querying of records.

```
private static DbCommandTree HandleDeleteCommand(DbDeleteCommandTree deleteCommand)
{
    var setClauses = new List<DbModificationClause>();
    var table = (EntityType) deleteCommand.Target.VariableType.EdmType;

    if (table.Properties.All(p => p.Name != IsDeletedColumnName))
    {
        return deleteCommand;
    }

    setClauses.Add(DbExpressionBuilder.SetClause(
        deleteCommand.Target.VariableType.Variable(deleteCommand.Target.VariableName).Property(IsDeletedColumnName),
        DbExpression.FromBoolean(true)));

    return new DbUpdateCommandTree(
        deleteCommand.MetadataWorkspace,
        deleteCommand.DataSpace,
        deleteCommand.Target,
        deleteCommand.Predicate,
        setClauses.AsReadOnly(), null);
}
```

Deletion handling is simple. First check if a table has _IsDeleted_ column and then replace delete command tree with update command tree which sets _IsDeleted_ to _true_.

```
private static DbCommandTree HandleQueryCommand(DbQueryCommandTree queryCommand)
{
    var newQuery = queryCommand.Query.Accept(new SoftDeleteQueryVisitor());
    return new DbQueryCommandTree(
        queryCommand.MetadataWorkspace,
        queryCommand.DataSpace,
        newQuery);
}

public class SoftDeleteQueryVisitor : DefaultExpressionVisitor
{
    public override DbExpression Visit(DbScanExpression expression)
    {
        var table = (EntityType)expression.Target.ElementType;
        if (table.Properties.All(p => p.Name != IsDeletedColumnName))
        {
            return base.Visit(expression);
        }

        var binding = expression.Bind();
        return binding.Filter(
            binding.VariableType
                .Variable(binding.VariableName)
                .Property(IsDeletedColumnName)
                .NotEqual(DbExpression.FromBoolean(true)));
    }
}
```

For query handling, use helper expression visitor class - _SoftDeleteQueryVisitor_, to build new query command. _SoftDeleteQueryVisitor_ visits each element of an expression tree, so if there are some joins with other tables, it will check for _IsDeleted_ column there too. After it checked for _IsDeleted_ column, the new filter gets applied to filter out records with _IsDeleted_ column set to _true_.

The last step is interceptor registration. Create a class which inherits from _DbConfiguration_ - _Entity Framework_ scans your application for it and runs defined configuration. In the class constructor, add a new instance of _SoftDeleteInterceptor_ with _AddInterceptor_ method.

```
public class EntityFrameworkConfiguration : DbConfiguration
{
    public EntityFrameworkConfiguration()
    {
        AddInterceptor(new SoftDeleteInterceptor());
    }
}
```

# Created and Modified dates

Automatic _Created_ and _Modified_ date setting uses the same approach as for soft delete. I have to check for two cases - insert and update.

```
public class CreatedAndModifiedDateInterceptor : IDbCommandTreeInterceptor
{
    public const string CreatedColumnName = "Created";
    public const string ModifiedColumnName = "Modified";

    public void TreeCreated(DbCommandTreeInterceptionContext interceptionContext)
    {
        if (interceptionContext.OriginalResult.DataSpace != DataSpace.SSpace)
        {
            return;
        }

        var insertCommand = interceptionContext.Result as DbInsertCommandTree;
        if (insertCommand != null)
        {
            interceptionContext.Result = HandleInsertCommand(insertCommand);
        }

        var updateCommand = interceptionContext.OriginalResult as DbUpdateCommandTree;
        if (updateCommand != null)
        {
            interceptionContext.Result = HandleUpdateCommand(updateCommand);
        }
    }

    // ...
}
```

Both commands are handled by replacing set clauses for _Created_ and _Modified_ date columns. Insert command replaces both - _Created_ and _Modified_, but update command replaces only _Modified_ column value.

```
private static DbCommandTree HandleInsertCommand(DbInsertCommandTree insertCommand)
{
    var now = DateTime.Now;

    var setClauses = insertCommand.SetClauses
        .Select(clause => clause.UpdateIfMatch(CreatedColumnName, DbExpression.FromDateTime(now)))
        .Select(clause => clause.UpdateIfMatch(ModifiedColumnName, DbExpression.FromDateTime(now)))
        .ToList();

    return new DbInsertCommandTree(
        insertCommand.MetadataWorkspace,
        insertCommand.DataSpace,
        insertCommand.Target,
        setClauses.AsReadOnly(),
        insertCommand.Returning);
}

private static DbCommandTree HandleUpdateCommand(DbUpdateCommandTree updateCommand)
{
    var now = DateTime.Now;

    var setClauses = updateCommand.SetClauses
        .Select(clause => clause.UpdateIfMatch(ModifiedColumnName, DbExpression.FromDateTime(now)))
        .ToList();

    return new DbUpdateCommandTree(
        updateCommand.MetadataWorkspace,
        updateCommand.DataSpace,
        updateCommand.Target,
        updateCommand.Predicate,
        setClauses.AsReadOnly(), null);
}
```

_UpdateIfMatch_ is extension method which replaces clause with a new one if it's column name matches, otherwise returns original clause.

```
public static DbModificationClause UpdateIfMatch(
    this DbModificationClause clause,
    string property,
    DbExpression value)
{
    return clause.IsFor(property)
            ? DbExpressionBuilder.SetClause(clause.Property(), value)
            : clause;
}
```

I am using other extensions here - _IsFor_ and _Property_. Full code for extensions is available in this [gist](https://gist.github.com/marisks/3cc2e4f18048e2f0b7a5#file-extensions-cs).

And the last step again is interceptor registration.

```
public class EntityFrameworkConfiguration : DbConfiguration
{
    public EntityFrameworkConfiguration()
    {
        AddInterceptor(new SoftDeleteInterceptor());
        AddInterceptor(new CreatedAndModifiedDateInterceptor());
    }
}
```

# Summary

Convention based soft delete and created and modified date setting makes your code much simpler. Configuring _Entity Framework_ to do it is a bit complicated but possible.
