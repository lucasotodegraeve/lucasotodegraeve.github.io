---
title: "Introducing xsd2xml"
date: 2025-12-31
---

I wrote a library, [xsd2xml](https://github.com/lucasotodegraeve/xsd2xml),  to create random XML documents based on an XSD document. It’s not complete, and I don’t plan on developing it further. I think such a library could be useful for some sort of fuzzy testing. I got it to a point where it can generate a random document for the premis XSD.

## Showcase
Given the following `xsd:element` and its corresponding `xsd:complexType` definition.

```xml
<xsd:element name="objectIdentifier" type="objectIdentifierComplexType"/>

<xsd:complexType name="objectIdentifierComplexType">
	<xsd:sequence>
		<xsd:element ref="objectIdentifierType"/>
		<xsd:element ref="objectIdentifierValue"/>
	</xsd:sequence>
	<xsd:attribute name="simpleLink" type="xsd:anyURI"/>
</xsd:complexType>
```

We can generate an XML document with this code snippet.

```py
import xsd2xml

xsd2xml.generate("premis.xsd.xml", "ObjectIdentifier")
```

Serializing the generated Python object yields a valid `premis:objectIdentifier`.

```xml
<premis:objectIdentifier xmlns:premis="http://www.loc.gov/premis/v3">
  <premis:objectIdentifierType>icJaaeGzRe</premis:objectIdentifierType>
  <premis:objectIdentifierValue>harXwSJdnN</premis:objectIdentifierValue>
</premis:objectIdentifier>
```

Passing the root premis node would also have worked and returned a much longer XML document.

## Previous work
There are a few projects out there that accomplish the same function as this library. Some editors even have this functionality built in. However, the Python libraries that provide equivalent functionality are simple and limited. This library is not complete by any means, but it does get further than most Python libraries I’ve found.

In my initial search for existing projects, I surprisingly found more projects that go the other way around. They generate an XSD given an XML document.

## Explanation
The library works by recursively generating `xsd:elements`. The XML document is built bottom-up. The leaf nodes have simple types such as string, number, list, etc. These simple elements are easy to generate most of the time. However, they can be constrained using a variety of rules, which makes complicates the implementation. The simple types are packaged up inside complex elements. These can themselves be children of other complex elements and so forth.

The biggest challenge is not so much the implementation itself, but rather understanding the XSD specification. I’m not nearly brave enough to read the  [official WS3 specification for XSD](https://www.w3.org/TR/xmlschema11-1/), which is just so complicated to read. ChatGPT was a great help here to give brief descriptions of what is and isn’t allowed.



<a href="https://brainmade.org/">
	<img class="brainmade" src="/static/brainmade-black.svg"/>
</a>
