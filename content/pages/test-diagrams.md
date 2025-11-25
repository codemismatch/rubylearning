---
title: Diagram Testing
permalink: /test-diagrams/
layout: page
---

# Diagram Generation Testing

This page tests the diagram generation features in Typophic.

## Mermaid Diagrams

### Simple Flowchart

#> mermaid: caption="Simple flowchart showing process flow"
graph TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> A
    C --> E[End]
#!

### Sequence Diagram

#> mermaid: class="sequence-diagram"
sequenceDiagram
    participant User
    participant Browser
    participant Server
    User->>Browser: Click link
    Browser->>Server: HTTP Request
    Server->>Browser: HTML Response
    Browser->>User: Display page
#!

## Ditaa Diagrams

### Gap Buffer

#> ditaa: output=assets/generated/diagrams/gapbuffer.png caption="Gap buffer data structure"
+---+----+----+---+---+---+---+---+---+---+---+---+---+
| H |cBF0|cBF0| E | L | L | O |   | W | O | R | L | D |
+---+----+----+---+---+---+---+---+---+---+---+---+---+
      |     |
      +-----+
         |
         v
  Gap Buffer
#!

### Architecture Diagram

#> ditaa: output=assets/generated/diagrams/architecture.png
    +--------+       +----------+       +----------+
    | Client |------>| Frontend |------>| Backend  |
    +--------+       +----------+       +----------+
         |                                    |
         |                                    v
         |                             +----------+
         +<----------------------------| Database |
                                       +----------+
#!

## Testing Complete

If you can see the diagrams above, the feature is working correctly!
