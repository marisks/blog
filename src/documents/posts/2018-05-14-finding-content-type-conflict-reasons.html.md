---
layout: post
title: "Finding content type conflict reasons"
description: >
  <t render="markdown">
  Episerver Developer Tools are useful for finding issues in your project/website. There is a tab - "Content Type Analyzer" which displays the details of your content types. In some projects you may notice that some types have issues with synchronization - SynchronizationStatus has value "Conflict," but it does not provide any hint about the reason for the conflict.
  </t>
category:
tags: [EPiServer]
date: 2018-05-14
visible: true
---

NOTE: If you are not familiar with Episerver Developer Tools, you should check it on [GitHub](https://github.com/episerver/DeveloperTools).

After some research, I found that Developer Tools are just displaying the list of content type models loaded from the content type model repository. The content type model does not have any property with failure reasons - only the status property.

So I looked (using decompiler) how the status property is set and in which case it set the status to "Conflict." I found that it uses _ContentTypeModel.IsInSynch_ method. This method checks if the content type is same as the content type model by different properties. The calling code of the _IsInSynch_ will set the status to "Conflict" when _IsInSynch_ returns false. Unfortunately, _IsInSynch_ method doesn't return error list - just true or false.

For this reason, I have used all the checks performed in this method and collected all issues for my content types:

```csharp
public ActionResult ContentTypeConflictList()
{
    var all = _contentTypeModelRepository.List().ToList();
    var conflictedContentTypes = all.Where(x => x.State == SynchronizationStatus.Conflict);
    var conflictedPropertyTypes = all.Select(
        x => Tuple.Create(
            x,
            x.PropertyDefinitionModels.Where(
                p => p.State == SynchronizationStatus.Conflict)));

    var conflicts =
        conflictedContentTypes.Select(ContentTypeConflicts.From)
        .Union(conflictedPropertyTypes.SelectMany(
            x => x.Item2.Select(p => ContentTypeConflicts.From(p, x.Item1))))
        .ToList();
    return View("~/Views/Shared/ContentTypeConflicts.cshtml", conflicts);
}

public class ContentTypeConflicts
{
    public string ModelName { get; }
    private readonly List<string> _conflicts = new List<string>();

    private ContentTypeConflicts(string modelName)
    {
        ModelName = modelName;
    }

    public bool Empty => _conflicts.Count == 0;
    public IEnumerable<string> Conflicts => _conflicts;

    public void Add(string conflict)
    {
        _conflicts.Add(conflict);
    }

    public static ContentTypeConflicts From(ContentTypeModel model)
    {
        var conflicts = new ContentTypeConflicts(model.Name);

        var contentType = model.ExistingContentType;

        if (!(model.ModelType == null
            || model.ModelType.AssemblyQualifiedName == contentType.ModelTypeString))
        {
            conflicts.Add(
                $@"model.ModelType mismatch:
                {model.ModelType} vs {contentType.ModelTypeString}");
        }

        if (!string.Equals(model.Name, contentType.Name))
        {
            conflicts.Add(
                $@"model.Name mismatch:
                {model.Name} vs {contentType.Name}");
        }

        if (!(string.IsNullOrEmpty(model.Description)
            || string.Equals(model.Description, contentType.Description)))
        {
            conflicts.Add(
                $@"model.Description mismatch:
                {model.Description} vs {contentType.Description}");
        }

        if (!(string.IsNullOrEmpty(model.DisplayName)
            || string.Equals(model.DisplayName, contentType.DisplayName)))
        {
            conflicts.Add(
                $@"model.DisplayName mismatch:
                {model.DisplayName} vs {contentType.DisplayName}");
        }

        if (!(!model.Order.HasValue
            || model.Order.Value == contentType.SortOrder))
        {
            conflicts.Add(
                $@"model.Order mismatch:
                {model.Order.Value} vs {contentType.SortOrder}");
        }

        if (!(!model.Guid.HasValue
            || !(model.Guid.Value != contentType.GUID)))
        {
            conflicts.Add(
                $@"model.Guid mismatch:
                {model.Guid.Value} vs {contentType.GUID}");
        }

        if (!(!model.AvailableInEditMode.HasValue
            || model.AvailableInEditMode.Value == contentType.IsAvailable))
        {
            conflicts.Add(
                $@"model.AvailableInEditMode mismatch:
                {model.AvailableInEditMode.Value} vs {contentType.IsAvailable}");
        }

        if (conflicts.Empty)
        {
            conflicts.Add(
                "model.ACL mismatch");
        }

        return conflicts;
    }

    public static ContentTypeConflicts From(
        PropertyDefinitionModel model, ContentTypeModel containerModel)
    {
        var conflicts = new ContentTypeConflicts($"{containerModel.Name}-{model.Name}");

        var propertyDefinition = model.ExistingPropertyDefinition;

        if (!string.IsNullOrEmpty(model.TabName)
            && (TabIsNotPersisted(propertyDefinition.Tab)
               || !string.Equals(model.TabName, propertyDefinition.Tab.Name)))
        {
            conflicts.Add(
                $@"model.TabName mismatch:
                {model.TabName} vs {propertyDefinition.Tab.Name}");
        }

        if (!string.IsNullOrEmpty(model.Name)
            && !string.Equals(model.Name, propertyDefinition.Name))
        {
            conflicts.Add(
                $@"model.Name mismatch:
                {model.Name} vs {propertyDefinition.Name}");
        }

        if (!string.IsNullOrEmpty(model.Description)
            && !string.Equals(model.Description, propertyDefinition.HelpText))
        {
            conflicts.Add(
                $@"model.Description mismatch:
                {model.Description} vs {propertyDefinition.HelpText}");
        }

        if (!string.IsNullOrEmpty(model.DisplayName)
            && !string.Equals(model.DisplayName, propertyDefinition.EditCaption))
        {
            conflicts.Add(
                $@"model.DisplayName mismatch:
                {model.DisplayName} vs {propertyDefinition.EditCaption}");
        }

        if ((model.CultureSpecific ?? false) != propertyDefinition.LanguageSpecific)
        {
            conflicts.Add(
                $@"model.CultureSpecific mismatch:
                {model.CultureSpecific} vs {propertyDefinition.LanguageSpecific}");
        }

        if (model.Required.HasValue
            && model.Required.Value != propertyDefinition.Required)
        {
            conflicts.Add(
                $@"model.Required mismatch:
                {model.Required} vs {propertyDefinition.Required}");
        }

        if (model.Searchable.HasValue
            && model.Searchable.Value != propertyDefinition.Searchable)
        {
            conflicts.Add(
                $@"model.Required mismatch:
                {model.Searchable} vs {propertyDefinition.Searchable}");
        }

        if (model.AvailableInEditMode.HasValue
            && model.AvailableInEditMode.Value != propertyDefinition.DisplayEditUI)
        {
            conflicts.Add(
                $@"model.AvailableInEditMode mismatch:
                {model.AvailableInEditMode} vs {propertyDefinition.DisplayEditUI}");
        }

        if (model.Order.HasValue
            && model.Order.Value != propertyDefinition.FieldOrder)
        {
            conflicts.Add(
                $@"model.Order mismatch:
                {model.Order} vs {propertyDefinition.FieldOrder}");
        }

        return conflicts;
    }

    private static bool TabIsNotPersisted(TabDefinition tab)
    {
        if (tab != null)
            return tab.ID == -1;
        return true;
    }
}
```

Here I have created a type _ContentTypeConflicts_ which holds all errors and provides factory methods to create itself. I also found that there are two types responsible for the content types - _ContentTypeModel_ and _PropertyDefinitionModel_ - the first one for content types and the second one for property types. _ContentTypeConflicts_ uses both types when detecting errors.

For _ContentTypeModel_, ACL check used some internal Episerver APIs that it was hard to extract. So I just used ACL mismatch error as a fallback if the type is in conflict and there are no other errors.

And the last, I am collecting all errors in a controller action and displaying those in a view.
