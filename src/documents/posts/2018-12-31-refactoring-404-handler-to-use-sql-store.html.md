---
layout: post
title: "Refactoring 404 handler to use SQL store"
description: >
  <t render="markdown">
  The 404 handler used DDS as storage for redirects. While DDS has a simple API and is easy to use, it doesn't perform well. So I decided to refactor the 404 handler to support different stores and implemented a SQL store.
  </t>
category:
tags: [EPiServer]
date: 2018-12-31
visible: true
---

If you want to get started with the new version, head over to [Geta's blog](https://getadigital.com/blog/404-handler-with-performance-improvements-released/) for details.

# Refactoring steps

The first challenge I faced was that data access was mixed with some logic in a `DataStoreHandler`. However, it was not so easy to extract it out. So I started abstracting away the logic behind the `DataStoreHandler` and created an interface for it - `IRedirectsService` and implemented it in the `DataStoreHandler`. I didn't like method names in the `DataStoreHandler`. So I used different naming in `IRedirectsService`:

```csharp
public interface IRedirectsService
{
    IEnumerable<CustomRedirect> GetAll();
    IEnumerable<CustomRedirect> GetSaved();
    IEnumerable<CustomRedirect> GetIgnored();
    IEnumerable<CustomRedirect> GetDeleted();
    IEnumerable<CustomRedirect> Search(string searchText);
    void AddOrUpdate(CustomRedirect redirect);
    void AddOrUpdate(IEnumerable<CustomRedirect> redirects);
    void DeleteByOldUrl(string oldUrl);
    int DeleteAll();
    int DeleteAllIgnored();
}
```

This new interface works as a facade for all actions that could be done with a redirect.

The next task was extracting data access. I wanted to separate reads from writes. For writes, I have introduced a generic `IRepository` interface. For now, it just supports saving and deleting of requests.

```csharp
public interface IRepository<TEntity>
    where TEntity : class
{
    void Save(TEntity entity);
    void Delete(TEntity entity);
}
```

For reads, I have created an interface specific for redirect querying - `IRedirectLoader`.

```csharp
public interface IRedirectLoader
{
    CustomRedirect GetByOldUrl(string oldUrl);
    IEnumerable<CustomRedirect> GetAll();
    IEnumerable<CustomRedirect> GetByState(RedirectState state);
    IEnumerable<CustomRedirect> Find(string searchText);
}
```

I could use a query pattern here, but it would complicate things. I also wanted to stick to _Episerver_ naming convention (for example, `IContentLoader` for content querying in _Episerver_).

With these two interfaces, I could extract out data access. So I have implemented `DdsRedirectRepository` by extracting all data access logic from `DataStoreHandler`.

Once this was done, it was simple to move the rest of the `DataStoreHandler` logic into a separate `IRedirectsService` implementation and leave `DataStoreHandler` just for backward compatibility (if someone uses it). I have implemented `DefaultRedirectsService` which mostly coordinates data access.

# SQL store

As I have finished refactoring, I could start implementing SQL store. The first task was creating a new table and implement upgrade steps. The 404 handler has `Upgrader` class which already creates a table for suggestions. I have used it as an example for the redirects table. However, before implementation of it, `Upgrader` needed a refactoring. I have extracted all upgrade steps in separate methods so that it is easier to add new steps.

Once table creation was implemented in the `Upgrader`, I could start working on `SqlRedirectRepository`. I used _Episerver's_ `IDatabaseExecutor` to run _ADO.NET_ queries. For more straightforward data reading I have used [Linq to DataSet](https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/queries-in-linq-to-dataset).

```csharp
private IEnumerable<CustomRedirect> ExecuteEnumerableQuery(DbCommand command)
{
    var table = ExecuteDataTableQuery(command);

    return table
        .AsEnumerable()
        .Select(ToCustomRedirect);
}

private DataTable ExecuteDataTableQuery(DbCommand command)
{
    var adapter = _executor.DbFactory.CreateDataAdapter();
    if (adapter == null) throw new Exception("Unable to create DbDataAdapter");

    adapter.SelectCommand = command;
    var ds = new DataSet();
    adapter.Fill(ds);
    return ds.Tables[0];
}

private static CustomRedirect ToCustomRedirect(DataRow x)
{
    return new CustomRedirect(
        x.Field<string>("OldUrl"),
        x.Field<string>("NewUrl"),
        x.Field<bool>("WildCardSkipAppend"))
    {
        Id = Identity.NewIdentity(x.Field<Guid>("Id")),
        State = x.Field<int>("State")
    };
}
```

The last step was adding data migration from DDS to the SQL store. I have just added an action to the gadget's controller, then used the `DdsRedirectRepository` to read old records and the new `IRedirectsService` to save records.

# Performance

After I have implemented SQL store, I wanted to see how much faster the 404 handler become. I have imported `6000` redirects in DDS and SQL stores and tried to load all redirects. The results were fascinating. Loading of all records from DDS store took `~16000 ms` while from SQL store it took only `26 ms`. It is more than 600 times faster.

# Summary

While it didn't seem much work implementing support for multiple storages, it took some time to finish it. Ideally, I would write integration tests to make sure that nothing was broken, but it was too hard to implement those to work with _Episerver APIs_ - DDS and SQL.

\# New Year!