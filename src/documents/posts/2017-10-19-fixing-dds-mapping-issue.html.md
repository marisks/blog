---
layout: post
title: "Fixing DDS mapping issue"
description: >
  <t render="markdown">
  Time to time I am getting an issue with DDS mapping mismatch. In this article, I will show the possible solutions.
  </t>
category:
tags: [EPiServer]
date: 2017-10-19
visible: true
---

An error you typically get looks like this:

```
The Type 'EPiServer.Personalization.VisitorGroups.VisitorGroupCriterion' needs to be remapped in the Dynamic Data Store, see the Errors collection for more information.
Remapping can be done by applying the EPiServer.Data.Dynamic.EPiServerDataStoreAttribute attribute to the type,
setting its AutomaticallyRemapStore property to true and ensuring the <episerver.dataStore><dataStore> autoRemapStores attribute in web.config is set to true (or is not defined).
EPiServer.Data.Dynamic.StoreInconsistencyException: The Type 'EPiServer.Personalization.VisitorGroups.VisitorGroupCriterion' needs to be remapped in the Dynamic Data Store, see the Errors collection for more information.
Remapping can be done by applying the EPiServer.Data.Dynamic.EPiServerDataStoreAttribute attribute to the type,
setting its AutomaticallyRemapStore property to true and ensuring the <episerver.dataStore><dataStore> autoRemapStores attribute in web.config is set to true (or is not defined).
```

While suggested solutions in the error description might help for your code, those will be hard to implement for the Episerver or 3rd party libraries.

When this issue occurred first time, I have used a suggested solution from Episerver:

```csharp
[HttpPost]
public ActionResult Remap()
{
    var errors = new StringBuilder();
    foreach (var storeDefinition in StoreDefinition.GetAll())
    {
        try
        {
            var type = TypeResolver.GetType(storeDefinition.StoreName);
            if (type != null)
            {
                storeDefinition.Remap(type);
                storeDefinition.CommitChanges();
            }
            else
            {
                var provider = _dataStoreProviderFactory.Create();
                provider.SaveStoreDefinition(storeDefinition);
            }
        }
        catch (Exception ex)
        {
            errors.AppendLine($"Error remapping '{storeDefinition.StoreName}': {ex.Message} {ex.StackTrace}");
        }
    }

    ViewBag.Error = errors.ToString();
    ViewBag.Success = string.IsNullOrEmpty(ViewBag.Error);

    return View("Index");
}
```

Here I am getting all store definitions and trying to resolve its type by the store name. Then I am calling remapping explicitly and storing the result.

This solution works when the store name is the full type name. But in the case with _VisitorGroupCriterion_, the name of the store is _VisitorGroupCriterion_. So the next simplest solution is listing of such store types and remapping explicitly.

```csharp
private void RemapExplicitly(StringBuilder errors)
{
    var explicitTypes = new[]
    {
        typeof(VisitorGroupCriterion)
    };

    var definitions = StoreDefinition
        .GetAll()
        .Where(x => explicitTypes.Any(t => t.Name.Equals(x.StoreName)))
        .Select(x => (x, explicitTypes.First(t => t.Name.Equals(x.StoreName))));

    foreach (var (definition, type) in definitions)
    {
        try
        {
            definition.Remap(type);
            definition.CommitChanges();
        }
        catch (Exception ex)
        {
            errors.AppendLine($"Error remapping '{definition.StoreName}': {ex.Message} {ex.StackTrace}");
        }
    }
}
```

Here I am expecting that store name is same as the type name (short name). But if you have a case where you have an entirely different name, you can modify the code to use it when looking for the store definition.


