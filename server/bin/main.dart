import 'package:serverpod/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:rice_url_shortener_server/src/bootstrap/database_bootstrap.dart';
import 'package:rice_url_shortener_server/src/web/routes/api_route.dart';
import 'package:rice_url_shortener_server/src/web/routes/health_route.dart';
import 'package:rice_url_shortener_server/src/web/routes/redirect_route.dart';

void main(List<String> args) async {
  // InitializeServerpod with Serverpod-supported CLI args
  final serverpodArgs = args.where((a) => a != '--bootstrap-db').toList();
  final pod = Serverpod(
    serverpodArgs,
    Protocol(),
    Endpoints(),
  );

  // Register Web Routes
  // 1. Health check route for ALB and Docker HEALTHCHECK
  pod.webServer.addRoute(HealthRoute(), '/health');

  // 2. REST API route for Flutter client RPC (/api/link/*, /api/analytics/*)
  pod.webServer.addRoute(ApiRoute(), '/api/*');

  // 3. High-speed URL redirect route for shortened links (/:code)
  pod.webServer.addRoute(RedirectRoute(), '/*');

  // Start the serverpod runtime
  await pod.start();

  // Automatically initialize database tables and seed demo links (idempotent)
  await DatabaseBootstrap.initialize(pod);
}

/// Fallback protocol and endpoints definitions for standalone initialization
class Protocol extends SerializationManagerServer {
  @override
  String getModuleName() => 'rice_url_shortener';

  @override
  Table? getTableForType(Type t) => null;

  @override
  List<TableDefinition> getTargetTableDefinitions() => [];

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? object) => null;

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) => null;
}

class Endpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Server server) {}
}
