---
layout: post
title: "EpiEvents for Commerce"
description: >
  <t render="markdown">
  Recently I have created an EpiEvents support for main Commerce events - InventoryUpdated and PriceUpdated.
  </t>
category:
tags: [EPiServer]
date: 2018-04-21
visible: true
---

Install the library using _NuGet_:

```powershell
Install-Package EpiEvents.Commerce
```

After installation, follow [configuration documentation](https://github.com/marisks/EpiEvents#configure).

Once, the library is installed in your project and configured correctly, you can start creating event handlers.

Here is an example of the _PriceUdpated_ event handler:

```csharp
public class PriceUpdatedHandler : INotificationHandler<PriceUpdated>
{
    private readonly ReferenceConverter _referenceConverter;
    private readonly IContentLoader _contentLoader;

    public PriceUpdatedHandler(ReferenceConverter referenceConverter, IContentLoader contentLoader)
    {
        _referenceConverter = referenceConverter;
        _contentLoader = contentLoader;
    }

    public void Handle(PriceUpdated notification)
    {
        foreach (var key in notification.CatalogKeys)
        {
            var link = _referenceConverter.GetContentLink(key.CatalogEntryCode);
            var content = _contentLoader.Get<CatalogContentBase>(link);

            // Do something with the content
        }
    }
}
```

InventoryUpdated event handler will look the same except that you have to pass the InventoryUpdated event type as a generic parameter.

For more information check [GitHub repository](https://github.com/marisks/EpiEvents).