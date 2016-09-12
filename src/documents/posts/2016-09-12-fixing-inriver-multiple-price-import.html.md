---
layout: post
title: "Fixing InRiver multiple price import"
description: "In one EPiServer Commerce project, I needed to import multiple prices for a variation in different currencies from InRiver. InRiver has a connector for EPiServer but unfortunately it supports only one price per variation."
category:
tags: [EPiServer,InRiver]
date: 2016-09-12
visible: true
---
<p class="lead">
In one EPiServer Commerce project, I needed to import multiple prices for a variation in different currencies from InRiver. InRiver has a connector for EPiServer but unfortunately it supports only one price per variation.
</p>

Luckily _InRiver_ import has an option to create a handler which can be used to modify import _XML_ before importing into _Commerce_. The handler should implement _ICatalogImportHandler_ interface. It has two methods - _PreImport_ and _PostImport_. In my case, I left _PostImport_ empty and implemented _PreImport_.

```
[ServiceConfiguration(ServiceType = typeof(ICatalogImportHandler))]
public class PriceImportHandler : ICatalogImportHandler
{
  public void PreImport(XDocument catalog)
  {
    var variations = catalog.XPathSelectElements("/Catalogs/Catalog/Entries/Entry[EntryType = 'Variation']");
    foreach (var variation in variations)
    {
      var prices = GetPrices(variation);
      var priceElements = CreatePriceElements(prices);
      var pricesElement = variation.Element("Prices");
      if (pricesElement == null)
      {
        pricesElement = new XElement("Prices");
        variation.Add(pricesElement);
      }
      pricesElement.ReplaceAll(priceElements);
    }
  }

  // ...

  }
}
```

First of all, get all variation entries. Then for each entry read price info from your custom fields of variation, create price XML elements from price info and add those to _Prices_ element of variation entry.

Reading prices from variation entry is simple.

```
private static readonly string[] AllowedCurrencies = {"NOK", "DKK", "SEK"};

private IEnumerable<Tuple<double, string>> GetPrices(XElement variation)
{
  return AllowedCurrencies.Select(currency => GetPrice(variation, currency));
}

public Tuple<double, string> GetPrice(XElement entry, string currencyCode)
{
  var priceMetaFieldElement =
    entry.XPathSelectElement(
      $@"./MetaData/MetaFields/MetaField[Name=""Price{currencyCode}""]");
  if (priceMetaFieldElement == null)
  {
    return null;
  }

  var priceElement = priceMetaFieldElement.XPathSelectElement("./Data");
  double price;
  double.TryParse(priceElement.Attribute("value").Value, out price);

  return Tuple.Create(price, currencyCode);
}
```

I have a convention that price fields in the _InRiver_ are in the format "Price{Currency code}". So I am getting prices for all available currencies.

Price element XML is simple, so creating XML elements for prices is straight forward.

```
private IEnumerable<XElement> CreatePriceElements(IEnumerable<Tuple<double, string>> prices)
{
  var validFrom = DateTime.UtcNow;
  var validUntil = DateTime.MaxValue;
   return
    prices.Select(
      priceInfo =>
        CreatePrice(
          "DEFAULT", priceInfo.Item2, priceInfo.Item1, validFrom, validUntil));
}

private XElement CreatePrice(
  string marketId, string currencyCode, double unitPrice, DateTime validFrom, DateTime validUntil)
{
  return new XElement(
    "Price",
    new XElement("MarketId", marketId),
    new XElement("CurrencyCode", currencyCode),
    new XElement("PriceTypeId", "0"),
    new XElement("PriceCode", string.Empty),
    new XElement("ValidFrom", validFrom.ToString("u")),
    new XElement("ValidUntil", validUntil.ToString("u")),
    new XElement("MinQuantity", "0"),
    new XElement("UnitPrice", unitPrice.ToString(CultureInfo.InvariantCulture)));
}
```

In this example, I am using default market and "generated" valid from/until dates but you might want to change this behavior for your needs.

Here is a full example:

```
[ServiceConfiguration(ServiceType = typeof(ICatalogImportHandler))]
public class PriceImportHandler : ICatalogImportHandler
{
  public void PreImport(XDocument catalog)
  {
    var variations = catalog.XPathSelectElements("/Catalogs/Catalog/Entries/Entry[EntryType = 'Variation']");
    foreach (var variation in variations)
    {
      var prices = GetPrices(variation);
      var priceElements = CreatePriceElements(prices);
      var pricesElement = variation.Element("Prices");
      if (pricesElement == null)
      {
        pricesElement = new XElement("Prices");
        variation.Add(pricesElement);
      }
      pricesElement.ReplaceAll(priceElements);
    }
  }

  private IEnumerable<XElement> CreatePriceElements(IEnumerable<Tuple<double, string>> prices)
  {
    var validFrom = DateTime.UtcNow;
    var validUntil = DateTime.MaxValue;
     return
      prices.Select(
        priceInfo =>
          CreatePrice(
            "DEFAULT", priceInfo.Item2, priceInfo.Item1, validFrom, validUntil));
  }

  private XElement CreatePrice(
    string marketId, string currencyCode, double unitPrice, DateTime validFrom, DateTime validUntil)
  {
    return new XElement(
      "Price",
      new XElement("MarketId", marketId),
      new XElement("CurrencyCode", currencyCode),
      new XElement("PriceTypeId", "0"),
      new XElement("PriceCode", string.Empty),
      new XElement("ValidFrom", validFrom.ToString("u")),
      new XElement("ValidUntil", validUntil.ToString("u")),
      new XElement("MinQuantity", "0"),
      new XElement("UnitPrice", unitPrice.ToString(CultureInfo.InvariantCulture)));
  }

  private static readonly string[] AllowedCurrencies = {"NOK", "DKK", "SEK"};

  private IEnumerable<Tuple<double, string>> GetPrices(XElement variation)
  {
    return AllowedCurrencies.Select(currency => GetPrice(variation, currency));
  }

  public Tuple<double, string> GetPrice(XElement entry, string currencyCode)
  {
    var priceMetaFieldElement =
      entry.XPathSelectElement(
        $@"./MetaData/MetaFields/MetaField[Name=""Price{currencyCode}""]");
    if (priceMetaFieldElement == null)
    {
      return null;
    }

    var priceElement = priceMetaFieldElement.XPathSelectElement("./Data");
    double price;
    double.TryParse(priceElement.Attribute("value").Value, out price);

    return Tuple.Create(price, currencyCode);
  }

  public void PostImport(XDocument catalog)
  {
  }
}
```
