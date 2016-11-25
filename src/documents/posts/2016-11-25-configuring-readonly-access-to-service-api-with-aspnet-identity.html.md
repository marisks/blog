---
layout: post
title: "Configuring read-only access to the Service API with ASP.NET Identity"
description: "Recently I had to configure read-only access to the Service API. ASP.NET Identity is used in this project and I was not able to make it work. The project was EPiServer 9 project. So I wanted to check if it is fixed in the EPiServer 10."
category:
tags: [EPiServer]
date: 2016-11-25
visible: true
---

<p class="lead">
Recently I had to configure read-only access to the Service API. ASP.NET Identity is used in this project and I was not able to make it work. The project was EPiServer 9 project. So I wanted to check if it is fixed in the EPiServer 10.
</p>

# Configuring read-only Service API access

First of all, [ASP.Identity should be configured for Service API](http://marisks.net/2016/08/31/service-api-authentication-with-new-identity/). The process for _EPiServer 10_ is same as for _EPiServer 9_.

## Creating read-only user group and user

Creating user group and a user are simple. With [AspNetIdentity](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Security/episerver-aspnetidentity/) package default administrative user interface works. Navigate to the _Admin -> Administer Groups_ and add a new group.

<img src="/img/2016-11/create-read-only-service-api-group.png" class="img-responsive" alt="Read-only user group creation view">

Next step is creating the user. Open _Admin -> Create User_ and fill in _Service API_ user's information. Add the user to the newly created read-only group.

<img src="/img/2016-11/create-read-only-service-api-user.png" class="img-responsive" alt="Read-only user creation view">

## Adding read-only access to Service API

Access to the _Service API_ can be configured under _Config -> Permissions for Functions_. Here edit _ReadAccess_ under _EPiServerServiceApi_.

<img src="/img/2016-11/read-access-to-service-api.png" class="img-responsive" alt="Permissions to functions view">

By default, only _Administrators_ are listed here. Add read-only user group here too.

<img src="/img/2016-11/read-access-to-service-api-read-only-group.png" class="img-responsive" alt="Permissions to functions group adding view">

## Testing

To test the setup, it is possible to create automated test which authenticates against site's _Service API_. For this purpose, I have created a base class to use for all _Service API_ tests.

```
public abstract class ApiTestsBase : IDisposable
{
    private const string Username = "RadOnlyService";
    private const string Password = "Episerver123%";

    protected readonly HttpClient Client;
    private const string IntegrationUrl =
      "https://readonly-serviceapi.localtest.me";

    protected ApiTestsBase()
    {
        ServicePointManager.ServerCertificateValidationCallback +=
            (sender, cert, chain, sslPolicyErrors) => true;
        Client = new HttpClient
        {
            BaseAddress = new Uri(IntegrationUrl)
        };
        Authenticate(Client);
    }

    public void Dispose()
    {
        Client.Dispose();
    }

    private void Authenticate(HttpClient client)
    {
        var fields = new Dictionary<string, string>
            {
                { "grant_type", "password" },
                { "username", Username },
                { "password", Password }
            };
        var response = client.PostAsync(
            "/episerverapi/token",
            new FormUrlEncodedContent(fields)).Result;
        if (!response.IsSuccessStatusCode)
        {
            throw new Exception(
              $"Authentication failed! Status: {response.StatusCode}");
        }

        var content = response
            .Content
            .ReadAsStringAsync()
            .Result;
        var token = JObject
            .Parse(content)
            .GetValue("access_token")
            .ToString();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
    }
}
```

First of all, the base class makes sure that SSL certificate validation is ignored as you might have only a local certificate installed which does not validate. Then it makes authentication request against _Service API_.

The actual authentication test is simple - just assert that no exception is thrown.

```
public class AuthenticationTests : ApiTestsBase
{
    [Fact]
    public void it_authenticates()
    {
        Assert.True(true);
    }
}
```

Next step is creating tests against _Service API_ endpoints to get "read-only" data. With a base class in place, it is simple.

```
public class CatalogTests : ApiTestsBase
{
  [Fact]
  public void it_can_retrieve_catalogs()
  {
      var response =
          Client.GetAsync("/episerverapi/commerce/catalogs")
              .Result;

      Assert.True(response.IsSuccessStatusCode);
      Assert.Equal(response.StatusCode, HttpStatusCode.OK);
  }
}
```

This test ensures that our user can retrieve catalogs from _Service API_.

Next test is a little bit more complicated. This test verifies that user is unable to modify anything. For this purpose, I am trying to create a new catalog. I took an example from [EPiServer documentation](http://world.episerver.com/documentation/developer-guides/Episerver-Service-API/catalog-restful-operations/). I took _Catalog_ and _CatalogLanguage_ classes from there.

```
[Fact]
public void it_fails_to_post_catalog()
{
    var model = new Catalog
    {
        DefaultCurrency = "usd",
        DefaultLanguage = "en",
        EndDate = DateTime.UtcNow.AddYears(1),
        IsActive = true,
        IsPrimary = true,
        Languages = new List<CatalogLanguage>
        {
            new CatalogLanguage
            {
                Catalog = "Test Post",
                LanguageCode = "en",
                UriSegment = "Test Post"
            }
        },
        Name = "Test Post",
        StartDate = DateTime.UtcNow,
        WeightBase = "lbs"
    };
    var json = JsonConvert.SerializeObject(model);
    var response = Client.PostAsync(
        "/episerverapi/commerce/catalogs",
        new StringContent(json, Encoding.UTF8, "application/json")).Result;

    Assert.False(response.IsSuccessStatusCode);
    Assert.Equal(response.StatusCode, HttpStatusCode.Unauthorized);
}
```

# Issues with EPiServer 9

While it is quite easy to setup _Service API_ read-only access in _EPiServer 10_, I couldn't make it in _EPiServer 9_. I have stuck on granting access rights to my custom user group. At first, I tried to add read-only rights to the user group directly in the database.

<img src="/img/2016-11/epi9-read-access-to-service-api-db.png" class="img-responsive" alt="Adding read-only access rights in the database view">

After that user still was not able to access _Service API_.

Then I tried to setup through UI. But I couldn't find my user group there. Instead, it listed built-in groups and some _Windows_ groups.

<img src="/img/2016-11/epi9-read-access-to-service-api-read-only-group.png" class="img-responsive" alt="Missing read-only group in the group search view">

So if you are using _ASP.NET Identity_ package and need a read-only access to _Service API_, you should upgrade to _EPiServer 10_.
