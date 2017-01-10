---
layout: post
title: "Service API authentication with new AspNetIdentity OWIN"
description: >
  <t render="markdown">
  EPiServer recently released a [package](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Security/episerver-aspnetidentity/) which adds support for ASP.NET identity in the CMS project. While it works great with CMS UI authentication, Service API configuration is a little bit more complicated.
  </t>
category:
tags: [EPiServer]
date: 2016-08-31
visible: true
---

Setting up _ASP.NET Identity_ in the CMS project is documented on [EPiServer World](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Security/episerver-aspnetidentity/).

Setting up Service API starts with changing authentication from membership provider to _ASP.NET Identity_. To do that, you have to implement your own _OAuthAuthorizationServerProvider_.

```
public class IdentityAuthorizationProvider : OAuthAuthorizationServerProvider
{
  public override Task ValidateClientAuthentication(
                            OAuthValidateClientAuthenticationContext context)
  {
     context.Validated();
    return Task.FromResult(0);
  }

  public override async Task GrantResourceOwnerCredentials(
                            OAuthGrantResourceOwnerCredentialsContext context)
  {
    var signInManager =
          ServiceLocator.Current.GetInstance<SignInManager<ApplicationUser, string>>();
    var result = await signInManager.PasswordSignInAsync(
                                         context.UserName,
                                         context.Password,
                                         isPersistent: false,
                                         shouldLockout: false);
    if (result == SignInStatus.Success)
    {
      var identity = new ClaimsIdentity(context.Options.AuthenticationType);
      var principal = PrincipalInfo.CreatePrincipal(context.UserName);
      if (principal is GenericPrincipal)
      {
        var generic = principal as GenericPrincipal;
        identity.AddClaims(generic.Claims);
      }

      context.Validated(identity);
    }
    else
    {
      context.Rejected();
    }
  }
}
```

You have to implement two methods - _ValidateClientAuthentication_ and _GrantResourceOwnerCredentials_. Authentication is implemented in the _GrantResourceOwnerCredentials_ method and it just uses _ASP.NET Identity's_ _SignInManger_ for your application user to sign in with a password. You can retrieve username and password for signing in from the context. Username and password are populated with values from _Service API_ authentication request. Then if the sign in is successful, create claims identity and call a _Validated_ method on the context. If the sign in was not successful, call _Rejected_.

Next step is registering _IdentityAuthorizationProvider_ in the _StructureMap_ container:

```
For<IOAuthAuthorizationServerProvider>().Use<IdentityAuthorizationProvider>();
```

The last step is checking that _EPiServer ASP.NET Identity's_ _OWIN Startup_ configuration is called the last - after your authentication configuration calls in the _Startup_ class.

```
public class Startup
{
    public void Configuration(IAppBuilder app)
    {
        app.AddCmsAspNetIdentity<ApplicationUser>();

        app.UseCookieAuthentication(new CookieAuthenticationOptions
        {
            AuthenticationType = DefaultAuthenticationTypes.ApplicationCookie,
            LoginPath = new PathString("/Util/Login.aspx"),
            Provider = new CookieAuthenticationProvider
            {
             OnValidateIdentity = SecurityStampValidator.OnValidateIdentity<ApplicationUserManager<ApplicationUser>, ApplicationUser>(
               validateInterval: TimeSpan.FromMinutes(30),
               regenerateIdentity: (manager, user) => manager.GenerateUserIdentityAsync(user))
            }
        });

        new EPiServer.ServiceApi.Startup().Configuration(app);
    }
}
```

If you call _EPiServer ASP.NET Identity's_ _OWIN Startup_ configuration before _app.AddCmsAspNetIdentity<ApplicationUser>()_ call, then _SignInManger_ will not be available in the _IdentityAuthorizationProvider_ and you will get an exception. _app.AddCmsAspNetIdentity<ApplicationUser>()_ registers all required services for authentication (including _SignInManager_) in the OWIN context.

# Summary

It is really nice that _EPiServer_ created a package for _ASP.NET Identity_ but it is missing some parts. For example, it could have _OAuthAuthorizationServerProvider_ implementation available and also all the registration set up.
