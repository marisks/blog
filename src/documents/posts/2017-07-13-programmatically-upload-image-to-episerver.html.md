---
layout: post
title: "Programmatically upload image to Episerver"
description: >
  <t render="markdown">
  When importing data into Episerver - CMS or Commerce, it is a common task to upload images. In this article I will show how to do it from the remote URL.
  </t>
category:
tags: [EPiServer]
date: 2017-07-13
visible: true
---

The first part is getting the image stream which can be written into an _Episerver_ blob.

```csharp
private async Task<Stream> GetImageStreamAsync(string url)
{
    var stream = new MemoryStream();

    try
    {
        var client = new HttpClient();
        var response = await client.GetAsync(url);
        response.EnsureSuccessStatusCode();

        var responseStream = await response.Content.ReadAsStreamAsync();

        var img = Image.FromStream(responseStream);

        var encoder = GetEncoder(img.RawFormat);
        var encoderParameters = GetEncoderParameters();

        img.Save(stream, encoder, encoderParameters);

        stream.Seek(0, SeekOrigin.Begin);
    }
    catch (Exception)
    {
        stream = null;
    }

    return stream;
}

private static EncoderParameters GetEncoderParameters()
{
    var qualityEncoder = Encoder.Quality;
    var encoderParameters = new EncoderParameters(1);
    var qualityEncoderParameter = new EncoderParameter(qualityEncoder, 100L);
    encoderParameters.Param[0] = qualityEncoderParameter;
    return encoderParameters;
}

private ImageCodecInfo GetEncoder(ImageFormat format)
{
    return ImageCodecInfo
        .GetImageDecoders()
        .FirstOrDefault(codec => codec.FormatID == format.Guid);
}
```

Here I am using an _HttpClient_ to download the image by URL. Then I am creating an image stream from the response stream using an _Image_ class. It requires image encoder and its parameters. An image encoder can be loaded by its _GUID_ from the _ImageCodecInfo.GetImageDecoders()_. _ImageFormat_ is specific for the different type of images - JPEGs, PNGs, etc. The _Image.FromStream_ method detects the image's format from the response stream and sets it on the _RawFormat_ field. You can use this field to get image extension.

Once you get the stream, create a new image data file, create a blob, write the stream data into the blob and save the image data.

```csharp
public async Task<ContentReference> UploadImage(string url, string imageName, ContentReference folderLink)
{
    var imageFile = _contentRepository.GetDefault<ImageFile>(folderLink);
    imageFile.Name = imageName;
    using (var stream = await GetImageStreamAsync(url))
    {
        if (stream == null) return null;

        var blob = _blobFactory.CreateBlob(imageFile.BinaryDataContainer, Path.GetExtension(imageFile.Name));
        blob.Write(stream);
        imageFile.BinaryData = blob;
        return _contentRepository.Save(imageFile, SaveAction.Publish, AccessLevel.NoAccess);
    }
}
```

In this example, the _ImageFile_ class is image's data file which inherits from the _ImageData_. This contains all your image's meta-data. Use _IBlobFactory.CreateBlob_ to create a new blob for the image and use _Write_ method to write content to it. The blob is associated with the image data by _BinaryData_ property on the image data class. Finally, store the image data using _IContentRepository.Save_ method.