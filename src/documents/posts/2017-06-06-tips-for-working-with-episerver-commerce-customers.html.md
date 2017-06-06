---
layout: post
title: "Tips for working with Episerver Commerce customers"
description: >
  <t render="markdown">
  Last week I was working on the custom user interface for customer management and discovered two useful tips which help to work with customers in Episerver.
  </t>
category:
tags: [EPiServer]
date: 2017-06-06
visible: true
---

# Enable search by Email

When working with customers, you usually use a _CustomerContext_ class. It provides a method to search for a customer by a pattern.

```csharp
var criteria = "Tom Jones";
var contacts = _customerContext.GetContactsByPattern(criteria);
```

By default, it searches only in _FirstName_, _FullName_, _MiddleName_ and _LastName_ fields. But it is common to search a customer by _Email_ too.

The _CustomerContact_ class has a public static field - _TextProperties_ which lists all searchable fields of the customer contact. You can add any additional field to it if you want. As you want to initialize this field only once, it is wise to do it in an initialization module.

```csharp
[InitializableModule]
[ModuleDependency(typeof(EPiServer.Web.InitializationModule))]
public class Initialization : IInitializableModule
{
    public void Initialize(InitializationEngine context)
    {
        EnableCustomerContactSearchByEmail();
    }

    private static void EnableCustomerContactSearchByEmail()
    {
        CustomerContact.TextProperties = CustomerContact.TextProperties.Union(new[] {"Email"}).Distinct();
    }

    public void Uninitialize(InitializationEngine context)
    {
    }
}
```

Here I am adding _Email_ field, but it should be okay to add search on any meta-field.

# Working with customer groups

While customer groups have [documentation](https://world.episerver.com/documentation/developer-guides/commerce/customers/Customer-groups/), the documentation lacks any examples on how to work with those.

There is one class - _CustomerGroupLoader_ which has two methods. One method lists all available customer groups and the second one retrieves a customer group by name.

```csharp
var customerGroups = _customerGroupLoader.Get();
var partnerGroup = _customerGroupLoader.Get("Partner");
```

The method for listing all groups is useful for creating items for a select box on your customer management form.

```csharp
private IEnumerable<SelectListItem> GetCustomerGroups()
{
    return 
        new []
        {
            new SelectListItem { Value = "0", Text = "-"}
        }.Union(
        _customerGroupLoader.Get()
        .Select(
            x => new SelectListItem
            {
                Value = x.Id,
                Text = x.Name
            }));
}
```

