---
layout: post
title: "EPiServer custom tab ordering"
description: "EPiServer allows us to group content's properties into different tabs using GroupName parameter on DisplayAttribute. While it works fine, it doesn't order tabs I want. In this article, I will show a simple declarative way to control tab ordering."
category:
tags: [EPiServer]
date: 2016-01-30
visible: true
---
<p class="lead">
  EPiServer allows us to group content's properties into different tabs using _GroupName_ parameter on _DisplayAttribute_. While it works fine, it doesn't order tabs I want. In this article, I will show a simple declarative way to control tab ordering.
</p>

First of all, let's define a custom attribute. It has two properties - _Name_ and _Index_. _Name_ is a tab's name which is used on _DisplayAttribute's_ _GroupName_ parameter. _Index_ sets tab's sort index.

```
[AttributeUsage(AttributeTargets.Class, AllowMultiple = true)]
public class CustomTabAttribute : Attribute
{
    public CustomTabAttribute(string name, int index)
    {
        if (name == null) throw new ArgumentNullException("name");
        Name = name;
        Index = index;
    }

    public string Name { get; private set; }
    public int Index { get; private set; }
}
```

Next step, is registering of this attribute in _ITabDefinition_ repository. So, create a new initializable module and in the _Initialize_ method look up for all content types which uses our new _CustomTab_. Then add found tabs to the tab definition repository.

```
public void Initialize(InitializationEngine context)
{
    var tabDefinitionRepository =
                        ServiceLocator.Current.GetInstance<ITabDefinitionRepository>();
    var contentTypeRepo =
                        ServiceLocator.Current.GetInstance<IContentTypeRepository>();

    var customTabs = contentTypeRepo.List()
                        .SelectMany(CustomTabAttributes);

    foreach (var tab in customTabs)
    {
        AddTabToList(tabDefinitionRepository,
            new TabDefinition
            {
                Name = tab.Name,
                RequiredAccess = AccessLevel.Edit,
                SortIndex = tab.Index
            });
    }
}

private IEnumerable<CustomTabAttribute> CustomTabAttributes(ContentType x)
{
    if (x.ModelType == null)
    {
        return Enumerable.Empty<CustomTabAttribute>();
    }

    return Attribute.GetCustomAttributes(x.ModelType, typeof (CustomTabAttribute))
                    .Cast<CustomTabAttribute>();
}

private void AddTabToList(
  ITabDefinitionRepository tabDefinitionRepository,
  TabDefinition definition)
{
    var existingTab = GetExistingTabDefinition(tabDefinitionRepository, definition);

    if (existingTab != null)
    {
        definition.ID = existingTab.ID;
    }

    tabDefinitionRepository.Save(definition);
}

private static TabDefinition GetExistingTabDefinition(
  ITabDefinitionRepository tabDefinitionRepository,
  TabDefinition definition)
{
    return
        tabDefinitionRepository.List()
            .FirstOrDefault(t =>
                  t.Name.Equals(
                        definition.Name,
                        StringComparison.InvariantCultureIgnoreCase));
}
```

And here is the usage of new _CustomTab_. Just decorate your content type with _CustomTab_ attribute, give it a name (use constants for it), set index for the tab and add some property to this tab by setting _DisplayAttribute's_ _GroupName_ property with tab's name.

```
[ContentType(GUID = "a35c0203-e548-4918-b932-05205cc8c491", Order = 1)]
[CustomTab("Sidebar", 100)]
[CustomTab("Description", 110)]
public class StandardPage : EditorialPageBase
{
    [Display(Name = "Text", Order = 10, GroupName = "Description")]
    public virtual string Text { get; set; }

    [Display(Name = "Sidebar", Order = 10, GroupName = "Sidebar")]
    public virtual ContentArea SidebarContentArea { get; set; }
}
```
In the given example _Sidebar_ tab will be displayed before _Description_ tab.

<img src="/img/2016-01/custom-tab-1.png" alt="Sidebar tab on the left and Description tab on the right." class="img-responsive">

Now switch indexes of the attributes:

```
[CustomTab("Sidebar", 110)]
[CustomTab("Description", 100)]
```

And see that tab order is changed:

<img src="/img/2016-01/custom-tab-2.png" alt="Description tab on the left and Sidebar tab on the right." class="img-responsive">

For more information about tabs look at [EPiServer Documentation](http://world.episerver.com/documentation/Items/Developers-Guide/Episerver-CMS/9/Content/grouping-content-types-and-properties/).
