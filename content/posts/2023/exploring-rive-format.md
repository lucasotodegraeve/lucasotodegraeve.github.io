---
title: 'Exploring the Rive file format'
date: 2023-11-21
draft: true
---

<script src="https://unpkg.com/@rive-app/canvas@2.7.0"></script>

<!-- ![](https://camo.githubusercontent.com/44a89c1789e3be44736cc691818e9ac9a2dbbffa5a70931f991c08ec85d09fd8/68747470733a2f2f63646e2e726976652e6170702f726976655f6c6f676f5f6461726b5f62672e706e67) -->

<canvas id="canvas" style="width:100%;"></canvas>
<script>
    const r = new rive.Rive({
        src: "https://cdn.rive.app/animations/vehicles.riv",
        canvas: document.getElementById("canvas"),
        autoplay: true,
        stateMachines: "bumpy",
        onLoad: () => {
          r.resizeDrawingSurfaceToCanvas();
        },
    });
</script>



[Rive](https://rive.app/) is a tool to create interactive animations that run on all major platforms. It uses a custom binary file format which results in a small file size and memory footprint. In this post, I explore the format and see what we can learn from it.



## Why Rive?
The two big players in the vector graphics animation domain are Rive and [Lottie](https://lottiefiles.com/). Rive claims their solution is [faster, smaller and consumes less memory](https://rive.app/blog/rive-as-a-lottie-alternative). However, the Lottie format appears to be much more open than the Rive format, as is evident from the size of the [Rive format documentation](https://help.rive.app/runtimes/advanced_topics/format), which is only a single page compared to the size of the [Lottie documentation](https://lottiefiles.github.io/lottie-docs/), which spans a sizable repository/website.
## The runtime format
Rive files use the `.riv` extension. This table, taken from the Rive documentation, shows the different binary types one might encounter in the file format.

| Type                      | Description                                                                                |
| ------------------------- | ------------------------------------------------------------------------------- |
| variable unsigned integer | LEB128 variable encoded unsigned integer (abbreviated to varuint going forward) |
| unsigned integer          | 4 byte unsigned integer                                                         |
| string                    | unsigned integer followed by utf-8 encoded byte array of provided length        |
| float                     | 32 bit floating point number encoded in 4 byte IEEE 754                         |

It is for the most part clear and accurate. However, some types are not documented on their website. This is discussed  further in [[#Appendix A - List of binary types]]. The exact details of [LEB128](https://en.wikipedia.org/wiki/LEB128) integers are not important right now.

With this knowledge, we can start to read a `.riv` file. The first thing we'll encounter is the header, which has the following format, as described in the Rive documentation:

| Value         | Type                   | 
| ------------- | ---------------------- |
| Fingerprint   | 4 bytes                |
| Major Version | varuint                |
| Minor Version | varuint                |
| File ID       | varuint                |
| ToC           | byte aligned bit array |

The first four fields and their purpose (fingerprint, major and minor version and file ID) are quite self-explanatory. Following these is the ToC. However, the documentation surrounding this header field is not entirely clear in the official documentation and is discussed further in [[#Appendix B - The ToC]]. Luckily, we do not need it for our purposes of tinkering with the format.

After the header follows a list of objects. These objects define everything: shapes, text, vertices, animations, transitions between animations, and everything else. Each of these objects may have a list of properties, such as the object's name, x and y coordinates, and/or opacity. Both objects and properties are identified by a key. For example, a rectangle is identified by a key with value 7 and a Node by a key with value 2. The following example is taken from the Rive documentation.

| Data  | Type         | Description                                                                          |
| ----- | ------------ | ------------------------------------------------------------------------- |
| 2     | varuint      | object of type 2 (Node)                                                   |
| 13    | varuint      | X property for the Node                                                   |
| 100.0 | 4 byte float | the X value for the Node                                                  |
| 14    | varuint      | Y property for the Node                                                   |
| 22.0  | 4 byte float | the Y value for the Node                                                  |
| 0     | varuint      | Null terminator. Done reading properties and have completed reading Node. |

This begs the question, what are valid objects and which properties is each object allowed to have? The answer to this is found in a collection of JSON files located in the [C++ runtime repository](https://github.com/rive-app/rive-cpp/tree/master/dev/defs). Going through these files manually is not a great UX so I wrote a [Nushell](https://www.nushell.sh/) script to extract the data from these files and make a diagram using the [Mermaid](https://mermaid.js.org/), found in this project's repository. **todo: link repo**

Furthermore, the mapping from an object or property key to its name is also available in these JSON files. I created another Nushell script to extract this mapping for all objects and properties and put them in a convenient Python dictionary.

**DIAGRAM**

- a type of inheritance, defined in the files

Objects present in Rive files relate to each other in two ways. The first is through their place in the file. If a rectangle follows an artboard, then that rectangle belongs to that artboard. This holds for all the objects following an artboard until a new artboard is read, after which objects will belong to this new artboard. These objects relate to each other through what is called a context.

The second type of relationship between objects is through a direct reference. An object may have a property called `parentID`. The value of this property is the index of the object it refers to. Consider the following example.

```
0 Arboard
1 Shape
2 Rectangle
	parentID 1
```

Both `Shape` and `Rectangle` belong to `Arboard` through context. Furthermore, `Rectangle` is a child of `Shape` through its `parentID` property.

## Modifying a file
Now that we have a rough idea of what's inside a rive file, let's modify it. Our goal will be to remove the watermark which is placed automatically on exports of the free tier of their product. In the file shown here I only added a rectangle and named it "myRectangle". The Rive logo was embedded on export.

**Watermark .riv**

Opening this file and interpreting the bytes using the knowledge gained in the previous section reveals the following content. Only the relevant parts are shown here, as the majority of the file defines vertices.

```
Artboard - id 0                         <- Every file has one of these 
    width - '500.0'
	height - '500.0'
	defaultStateMachineId - '0'
	name - 'New Artboard'

// 1000+ lines of vertex data

Shape - id 321        
    name - 'Rectangle'
	parentId - '322'
	x - '91.0'
	y - '20.0'
Node - id 322                           <- Root of the watermark
    name - 'pasted.svg'
	x - '298.0'
	y - '440.0'


Shape - id 323                          <- Root of my rectangle
    name - 'MyRectangle'
	parentId - '0'
	x - '152.4208526611328'
	y - '176.53900146484375'
Rectangle - id 324        
    parentId - '323'
	width - '146.92201232910156'
	height - '146.92201232910156'

// some color stuff

LinearAnimation - id 333                  <- Animation stuff
    name - 'Timeline 1'
StateMachine - id 334        
    name - 'State Machine 1'
StateMachineLayer - id 335        
    name - 'Layer 1'
AnyState - id 336                
ExitState - id 337                
EntryState - id 338                
StateTransition - id 339        
    stateToId - '3'
AnimationState - id 340        
    animationId - '0'

```

The two most important objects here are the node with name "pasted.svg" and the shape with  name "MyRectangle". The first refers to the Rive logo while the second refers to the rectangle I placed using the Rive editor. 

Removing the node object and other objects related to it is the first step in removing the watermark but in doing so the file becomes invalid. This is because the indexes of the objects in the objects list will have shifted and because of this the `parentID` properties also need to be updated. If the original objects look like this.

```
Shape - id 323        
    name - 'MyRectangle'
Rectangle - id 324        
    parentId - '323'
```

And we remove all objects before  the `Shape` object, then its new ID will be 0. We still want the `parentID` to point to `Shape` though, so we must also update this value 
to 0.

```
Shape - id 0        
    name - 'MyRectangle'
Rectangle - id 1        
    parentId - '0'
```

For the task of removing the watermark, I decided to do this editing by hand, as is visible in this Python script. **todo link to file** Viewing the Rive file after the modifications gives the following result.

**todo: show riv**

Great succes. However, we might actually have taken the hard route to remove the watermark. If we go through the object definitions and their properties in the C++ Rive runtime repository, we'll encounter an object called `WorldTransformComponent` which has a property called `opacity` with key 18. Looking at the inheritance diagram in the previous sections, we see that `Node` extends `TransformComponent` which extends `WorldTransformComponent`. By simply adding this property to the  root of the watermark and setting its value to 0 we can also make it disappear.

```
Node - id 322        
    name - 'pasted.svg'
	x - '298.0'
	y - '440.0'
	opacity - '0'             <- added by us
```

**todo: show riv file**

Again, great succes. However, the difference between the two approaches in visible in their file sizes. Removing the watermark data yields a file with size 164 B, while simply setting the opacity to 0 gives a file that is 11.4 KB large.

## Conclusion
In this post we learned about the Rive file format and saw two methods of removing a watermark placed on exports of the free tier of their product. All the code used in this project is available at **todo: link repo**.

Personally, for this little project I took my first dip into Nushell scripting. It was a wonderful experience and hope the ecosystem quickly embraces fully so that i can get rid of my Bash shell. For the Python side of the project, I tried to apply some lessons I learned from a post called [Writing Python like it's Rust](https://kobzol.github.io/rust/python/2023/05/20/writing-python-like-its-rust.html).

## Appendix A - List of binary types

I'll first note that the color type is absent from table showing the different binary types. It represents a RGBA type and spans 4 bytes.  Secondly, the description for the string type mentions that the length of the string is encoded as an unsigned integer, even though it is actually encoded as a variable unsigned integer. 

## Appendix B - The ToC

The ToC is a field found in the header. It serves to inform the reader of (perhaps) newly added property keys and how to read them. Here property keys are simply an integer that uniquely identifies properties on objects. However, the explanation on how the ToC is structured less clear to me. In the documentation we find:

> The list of known properties is serialized as a sequence of variable unsigned integers with a 0 terminator. A valid property key is distinguished by a non-zero unsigned integer id/key. Following the properties is a bit array which is composed of the read property count / 4 bytes.

The documentation follows with a concrete example which appeared to illustrate the idea wel, but when implementing my own reader, I couldn't read the ToC properly and I had to look at the [Flutter implementation](https://github.com/rive-app/rive-flutter/blob/7cb9e8c18ee106235422b4f54928190ef5908e89/lib/src/rive_core/runtime/runtime_header.dart#L66-L84) of the binary reader to understand what is going. The documentation gives the following example.

| Value | Type       |
| ----- | ---------- |
| 12    | varuint    |
| 16    | varuint    |
| 6     | varuint    |
| 0     | terminator |
| 0     | 2 bits     |
| 1     | 2 bits     |
| 0     | 2 bits     |

From the explanation one would think that the 2 bit values are arranged one after each other like this:

```
00 01 00 00
```

Here two extra zero bits were added to the end in order to byte align whatever might come next. This is not how it actually works. For some reason the bit array is stored in chunks of 4 bytes.

```
00000000 00000000 00000000 00010000
^ padding                  ^ start
```

And only 8 bits are ever used per 32 bits. This means that if we had 5 values of 2 bits, it would something like this:

```
00000000 00000000 00000000 XXXXXXXX
^ padding                  ^ first 4 x 2 bits

00000000 00000000 00000000 000000XX
^ padding                        ^ 5th 2 bit value
```

I'm not sure why its done this way. Perhaps in case more different types are introduced and more than 2 bits are required to store them, this could already offer the necessary space.
