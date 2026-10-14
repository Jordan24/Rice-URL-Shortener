---
name: serverpod
description: Guidelines, project architecture, model definitions, database migrations, endpoints, and deployment patterns for Serverpod Dart backends.
---

# Serverpod Framework Skill Guide

Serverpod is the open-source Dart backend and app server framework designed specifically for Flutter developers. It generates client-side Dart libraries automatically and includes a built-in ORM for PostgreSQL.

## 1. Project Directory Layout
A standard Serverpod project follows a three-part monorepo structure:
- `server/`: The backend server application containing models, endpoints, database migrations, web handlers, and server configuration.
- `client/`: Auto-generated client SDK used by client applications (Flutter, command-line tools). Never edit generated files directly.
- `app/` (or root `lib/` in Flutter projects): The client application that consumes the `client/` package.

## 2. Serverpod Model Definitions (`.spy.yaml`)
Models are defined in YAML under `server/lib/src/models/` using the `.spy.yaml` extension:
```yaml
class: ShortLink
table: short_link
fields:
  linkId: String
  userId: String
  userEmail: String
  shortCode: String
  destinationUrl: String
  fallbackUrl: String?
  expiresAt: DateTime?
  isActive: bool
  clickCount: int
  lastClickedAt: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
  qrConfig: String?
indexes:
  short_code_idx:
    fields: shortCode
    unique: true
  user_id_idx:
    fields: userId
```

## 3. Endpoints (`server/lib/src/endpoints/`)
Endpoints inherit from `Endpoint` and define public RPC methods:
- Methods must be `async` and return a `Future<T>`.
- The first parameter must always be `Session session`.
- Session provides access to the database (`session.db`), logging, cache, and authentication state (`session.authenticated`).

Example:
```dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class LinkEndpoint extends Endpoint {
  Future<ShortLink?> getLink(Session session, String shortCode) async {
    return await ShortLink.db.findFirstRow(
      session,
      where: (t) => t.shortCode.equals(shortCode.toLowerCase()),
    );
  }
}
```

## 4. Web Routes & Redirection
Serverpod supports custom HTTP routes (subclassing `Route`) for handling raw web requests, webhooks, and HTTP redirects:
```dart
import 'dart:io';
import 'package:serverpod/serverpod.dart';

class RedirectRoute extends Route {
  @override
  Future<bool> handleCall(Session session, HttpRequest request) async {
    final path = request.uri.pathSegments;
    // Handle redirect logic, status 301/302
    request.response.redirect(Uri.parse(destination), HttpStatus.movedPermanently);
    return true;
  }
}
```

## 5. Configuration & Passwords
Configuration files reside in `server/config/`:
- `development.yaml`, `staging.yaml`, `production.yaml`: Database host, ports, logging level.
- `passwords.yaml`: Sensitive credentials (database passwords, API keys). Never commit real passwords to public git.

