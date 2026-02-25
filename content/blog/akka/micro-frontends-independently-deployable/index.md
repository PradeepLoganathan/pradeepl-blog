---
title: "Building Resilient Microservices with Akka — Part 4: Micro-Frontends — Independently Deployable from Database to Pixel"
lastmod: 2026-02-19T10:00:00+10:00
date: 2026-02-19T10:00:00+10:00
draft: true
Author: Pradeep Loganathan
tags:
  - akka
  - microservices
  - micro-frontends
  - web-components
  - angular
  - independently-deployable
  - distributed-systems
categories:
  - akka
  - architecture
description: "Completing the microservices independence story — manifest-driven micro-frontend discovery, Web Components as integration contracts, CDN-hosted versioned bundles, and live version switching without app store releases."
summary: "How to extend microservices independence to the UI layer with manifest-driven micro-app discovery, Angular Elements as Web Components, versioned CDN delivery, and live version switching — completing the full-stack independence story from event journal to UI pixel."
ShowToc: true
TocOpen: true
images:
  - "images/cover.png"
cover:
  image: "images/cover.png"
  alt: "Micro-frontends with independently deployable UI components"
  caption: "Independently deployable from database to pixel — micro-frontends that mirror the backend's decoupling philosophy"
  relative: true
---

{{< series-toc >}}

In [Part 1]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}}), we built event-sourced entities that capture every state change as an immutable fact. In [Part 2]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}}), we wired services together with platform-managed discovery, no URLs, no configuration. In [Part 3]({{< ref "/blog/akka/deployment-resilience-multi-region" >}}), we deployed to production and explored multi-region replication.

Throughout those three posts, we achieved something significant on the backend: each service is independently deployable, independently scalable, and independently evolvable. A change to the analysis-service does not require a coordinated release with the statement-service. Teams can ship on their own cadence.

But look at the frontend.

Most organizations still ship a monolithic web or mobile application. Every team's UI changes funnel into the same build pipeline, the same release train, the same app store submission. The backend was decoupled in the 2010s; the frontend is where independence goes to die.

In this final post, we complete the story. We will build a micro-frontend architecture where UI components are discovered at runtime through a manifest, loaded dynamically from a CDN, and rendered as Web Components, with no compile-time coupling between the shell application and the micro-apps it hosts. We will demonstrate live version switching: update a manifest file, refresh the browser, and see a new UI, no rebuild, no redeployment, no app store review.

The architecture mirrors the backend. The manifest registry is the frontend's service discovery. The CDN is the frontend's container registry. The Web Component is the frontend's API contract. From event journal to UI pixel, every layer is independently deployable.

![Micro-Frontend Architecture](images/micro-frontend-architecture.png)

## The Problem with Monolithic Frontends

Consider our banking demo. We have four backend services: statement, analysis, recommendation, and product. Each is deployed independently. But the mobile banking app that users interact with, how is it built?

In a typical architecture, it is a single Angular or React application. The "Statements" tab, the "Analysis" tab, and the "Recommendations" tab are all components compiled into one bundle. When the analysis team wants to add a "Top Merchants" section, they commit to the shared repository, wait for the pipeline to build the entire app, and ship a coordinated release. If the statements team is mid-refactor and their code is unstable, the analysis team waits.

This is the same coupling problem we solved on the backend, just wearing a different hat. The backend teams achieved independence through service decomposition. The frontend teams are still trapped in a monolith.

Micro-frontends solve this by applying the same decomposition principle to the UI. Each feature area becomes an independently built, independently deployed, independently versioned UI component. But most micro-frontend implementations, particularly those based on webpack Module Federation, introduce significant compile-time coupling, shared dependency management, and framework lock-in.

We will take a different approach. One that uses browser standards, avoids build-tool coupling, and mirrors the simplicity of the backend's `httpClientProvider.httpClientFor("service-name")` pattern.

## The Architecture: Three Moving Parts

The micro-frontend system has three components:

```
┌──────────────────────┐
│   Banking Shell       │
│   (Ionic Angular)     │     1. "What micro-apps exist?"
│                       │────────────────────────────────────┐
│   ┌─────────────────┐ │                                    │
│   │ MicroApp Loader │ │     2. Load script from CDN        │
│   │ ┌─────────────┐ │ │──────────────────────┐             │
│   │ │<mf-analysis>│ │ │                      │             │
│   │ └─────────────┘ │ │                      │             │
│   └─────────────────┘ │                      │             │
└────────────────────────┘                     │             │
                                               v             v
                                    ┌──────────────┐  ┌──────────┐
                                    │     CDN       │  │ Registry │
                                    │  (Port 8090)  │  │(Port 8079)│
                                    │               │  │           │
                                    │ /analysis/    │  │ manifest  │
                                    │   1.0.0/      │  │  .json    │
                                    │   2.0.0/      │  │           │
                                    │ /details/     │  │           │
                                    │   1.0.0/      │  │           │
                                    └──────────────┘  └──────────┘
```

**The Manifest Registry**, A lightweight server that serves a JSON manifest describing which micro-apps are available, what version to load, and where to find them. This is the frontend's equivalent of service discovery.

**The CDN**, A static file server that hosts versioned micro-app bundles. Each micro-app version gets its own directory. Multiple versions coexist simultaneously, v1.0.0 and v2.0.0 are both available; the manifest decides which one loads.

**The Shell**, The host application that users interact with. It fetches the manifest, dynamically loads micro-app scripts, and renders them as Web Components. It has zero compile-time knowledge of what micro-apps exist.

## The Manifest: Runtime Service Discovery for the Frontend

The manifest is a JSON file that describes the micro-frontend landscape:

```json
{
  "manifestVersion": "2026-02-18T00:00:00Z",
  "channel": "demo",
  "microfrontends": [
    {
      "name": "statement-details",
      "version": "1.0.0",
      "remoteEntry": "http://localhost:8090/statement-details/1.0.0/main.js",
      "exposedModule": "./Module",
      "elementTag": "mf-statement-details"
    },
    {
      "name": "statement-analysis",
      "version": "1.0.0",
      "remoteEntry": "http://localhost:8090/statement-analysis/1.0.0/main.js",
      "exposedModule": "./Module",
      "elementTag": "mf-statement-analysis"
    },
    {
      "name": "recommendations",
      "version": "1.0.0",
      "remoteEntry": "http://localhost:8090/recommendations/1.0.0/main.js",
      "exposedModule": "./Module",
      "elementTag": "mf-recommendations"
    }
  ]
}
```

Each entry has four essential fields:

- **name**, The micro-app identifier. The shell uses this to look up a specific micro-app.
- **version**, The semantic version currently active. This is what changes during a live update.
- **remoteEntry**, The URL of the JavaScript bundle. Includes the version in the path, so multiple versions coexist on the CDN.
- **elementTag**, The HTML custom element tag that the micro-app registers. This is the integration contract.

The parallel to backend service discovery is exact. On the backend, `httpClientProvider.httpClientFor("statement-service")` resolves a service name to an endpoint. On the frontend, `manifest.microfrontends.find(mf => mf.name === "statement-analysis")` resolves a micro-app name to a bundle URL. In both cases, the consumer knows only a name. The infrastructure resolves it to a concrete location.

### The Registry Server

The registry is deliberately simple, a Java HTTP server that reads manifest.json from disk and serves it with CORS headers:

```java
public class RegistryServer {

    private static final int PORT = 8079;

    public static void main(String[] args) throws IOException {
        Path manifestPath = resolveManifest();

        HttpServer server = HttpServer.create(new InetSocketAddress(PORT), 0);

        server.createContext("/microfrontends/manifest", exchange -> {
            addCorsHeaders(exchange);
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(204, -1);
                return;
            }

            String manifest = Files.readString(manifestPath);
            byte[] bytes = manifest.getBytes();
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });

        server.setExecutor(null);
        server.start();
    }
}
```

The registry reads the file on every request, it does not cache. This is deliberate. When you edit manifest.json to point to a new version, the next request from any browser picks up the change. No service restart, no cache invalidation, no deployment. Edit a file, refresh the browser, see the new version.

The simplicity is the point. The registry is a file server with a single endpoint. In production, this could be an S3 bucket, a CloudFront distribution, or a database-backed API. The protocol is what matters: an HTTP endpoint that returns a JSON manifest.

> **Production hardening:** Keep the S3 bucket private and serve bundles through CloudFront with an Origin Access Identity (or Origin Access Control). Use signed URLs or signed cookies to prevent unauthorized hotlinking of your bundles. Pin the manifest endpoint behind authentication so only your shell can discover micro-app locations. If you are not on AWS, the same principle applies: private storage + CDN edge auth + scoped access tokens.

## The CDN: Versioned Static Hosting

The CDN serves pre-built micro-app bundles. Its directory structure encodes the versioning scheme:

```
www/
├── statement-details/
│   └── 1.0.0/
│       └── main.js
├── statement-analysis/
│   ├── 1.0.0/
│   │   └── main.js
│   └── 2.0.0/
│       └── main.js
└── recommendations/
    └── 1.0.0/
        └── main.js
```

Notice that `statement-analysis` has both v1.0.0 and v2.0.0. Both are deployed. Both are available. The manifest decides which one is active. This is the frontend equivalent of blue-green deployment, both versions are live on the CDN; the manifest is the traffic router.

The CDN server resolves paths to files under the `www/` root, with security checks to prevent directory traversal:

```java
server.createContext("/", exchange -> {
    addCorsHeaders(exchange);

    String path = exchange.getRequestURI().getPath();
    Path filePath = wwwRoot.resolve(path.substring(1)).normalize();

    // Security: ensure file is within www root
    if (!filePath.startsWith(wwwRoot)) {
        sendText(exchange, 403, "Forbidden");
        return;
    }

    if (!Files.exists(filePath) || Files.isDirectory(filePath)) {
        sendText(exchange, 404, "Not found: " + path);
        return;
    }

    byte[] content = Files.readAllBytes(filePath);
    String ext = getExtension(filePath.getFileName().toString());
    String contentType = MIME_TYPES.getOrDefault(ext, "application/octet-stream");

    exchange.getResponseHeaders().add("Content-Type", contentType);
    exchange.getResponseHeaders().add("Cache-Control", "no-cache");
    exchange.sendResponseHeaders(200, content.length);
    try (OutputStream os = exchange.getResponseBody()) {
        os.write(content);
    }
});
```

The `Cache-Control: no-cache` header ensures browsers always check for the latest version. In production, you would use immutable URLs (the version is in the path, so `1.0.0/main.js` never changes) with long cache times, and let the manifest control which version is active.

## The Shell: Dynamic Loading Without Compile-Time Coupling

The shell is an Ionic Angular application that serves as the host for micro-apps. It has tabs, navigation, and chrome, but the actual feature content is loaded dynamically from micro-apps it knows nothing about at compile time.

### The MicroAppService: Manifest Fetching and Script Loading

The `MicroAppService` is the connection layer between the shell and the micro-frontend infrastructure:

```typescript
const MANIFEST_URL =
  'http://localhost:8079/microfrontends/manifest?channel=demo';

@Injectable({ providedIn: 'root' })
export class MicroAppService {
  private manifest: MicroAppManifest | null = null;
  private manifestLoading: Promise<MicroAppManifest> | null = null;
  private scriptStates = new Map<string, ScriptLoadState>();

  async fetchManifest(forceRefresh = false): Promise<MicroAppManifest> {
    if (this.manifest && !forceRefresh) {
      return this.manifest;
    }

    if (this.manifestLoading && !forceRefresh) {
      return this.manifestLoading;
    }

    this.manifestLoading = this.loadManifest();

    try {
      this.manifest = await this.manifestLoading;
      return this.manifest;
    } finally {
      this.manifestLoading = null;
    }
  }

  async getManifestEntry(
    name: string
  ): Promise<MicroAppManifestEntry | undefined> {
    const manifest = await this.fetchManifest(true);
    return manifest.microfrontends.find((mf) => mf.name === name);
  }
}
```

Three behaviors are worth noting:

**Force refresh on lookup.** `getManifestEntry` calls `fetchManifest(true)`, which always re-fetches the manifest from the registry. This means that if you edit the manifest to point to v2.0.0 and the user navigates to a new tab, the shell picks up the new version. No hard refresh required, just navigation.

**In-flight deduplication.** If two micro-apps request the manifest simultaneously, the second call returns the same promise as the first. This avoids duplicate HTTP requests during the initial page load when multiple loaders initialize in parallel.

**Script state tracking.** The service tracks which scripts have been loaded, which are currently loading, and which failed. This prevents duplicate script injection, a subtle but important concern when users navigate between tabs.

### Script Injection and Custom Element Registration

The actual loading happens through DOM API calls, no bundler, no Module Federation, no import maps:

```typescript
private injectScript(entry: MicroAppManifestEntry): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      // Check if script tag already exists
      const existingScript = document.querySelector(
        `script[data-microapp="${entry.name}"]`
      );
      if (existingScript) {
        this.waitForElement(entry.elementTag).then(resolve).catch(reject);
        return;
      }

      const script = document.createElement('script');
      script.src = entry.remoteEntry;
      script.type = 'text/javascript';
      script.setAttribute('data-microapp', entry.name);
      script.setAttribute('data-version', entry.version);

      script.onload = () => {
        this.waitForElement(entry.elementTag)
          .then(resolve)
          .catch(reject);
      };

      script.onerror = () => {
        script.remove();
        reject(new Error(
          `Failed to load script for "${entry.name}" from ${entry.remoteEntry}`
        ));
      };

      document.head.appendChild(script);
    });
  }
```

The sequence is:
1. Create a `<script>` tag with the bundle URL from the manifest
2. Add `data-microapp` and `data-version` attributes for debugging
3. Append it to `<head>`, the browser downloads and executes the script
4. Wait for the custom element to be registered in the browser's `CustomElementRegistry`

The wait step is critical. When the script executes, it bootstraps an Angular application and registers a custom element. This registration is asynchronous. The `waitForElement` method uses the browser's `customElements.whenDefined()` API with a 10-second timeout:

```typescript
private waitForElement(tagName: string): Promise<void> {
    if (customElements.get(tagName)) {
      return Promise.resolve();
    }

    return new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error(
          `Timed out waiting for custom element <${tagName}> to be defined`
        ));
      }, 10000);

      customElements.whenDefined(tagName)
        .then(() => {
          clearTimeout(timeout);
          resolve();
        })
        .catch((err) => {
          clearTimeout(timeout);
          reject(err);
        });
    });
  }
```

This is using browser standards, not a framework abstraction, not a bundler plugin. The `CustomElementRegistry` is a W3C specification supported by all modern browsers. The micro-app registers a tag name; the shell waits for that tag name to be available; then it creates an element. The integration contract is an HTML tag.

### The MicroAppLoader Component

The loader component orchestrates the three-step sequence, fetch manifest, load script, render element, with loading and error states:

```typescript
@Component({
  selector: 'app-microapp-loader',
  standalone: true,
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    @if (state === 'loading') {
      <div class="microapp-loading">
        <ion-spinner name="crescent" color="secondary"></ion-spinner>
        <p class="loading-text">Loading {{ microappName }}...</p>
      </div>
    }

    @if (state === 'error') {
      <div class="microapp-error">
        <ion-icon name="alert-circle-outline"></ion-icon>
        <p class="error-title">Unable to Load</p>
        <p class="error-message">{{ errorMessage }}</p>
        <ion-button fill="outline" size="small" (click)="retry()">
          <ion-icon name="refresh-outline" slot="start"></ion-icon>
          Retry
        </ion-button>
      </div>
    }

    <div #microappHost class="microapp-host"
      [style.display]="state === 'loaded' ? 'block' : 'none'">
    </div>
  `
})
export class MicroAppLoaderComponent implements OnInit, OnDestroy {
  @Input({ required: true }) microappName!: string;
  @ViewChild('microappHost', { static: true }) hostRef!: ElementRef<HTMLDivElement>;

  state: LoadingState = 'loading';
  errorMessage = '';

  async ngOnInit(): Promise<void> {
    await this.loadMicroApp();
  }

  private async loadMicroApp(): Promise<void> {
    try {
      // Step 1: Get the manifest entry
      const entry = await this.microAppService.getManifestEntry(this.microappName);
      if (!entry) {
        throw new Error(`Micro-app "${this.microappName}" not found in manifest`);
      }

      // Step 2: Load the remote script and wait for custom element
      await this.microAppService.loadMicroApp(entry);

      // Step 3: Render the custom element
      this.renderElement(entry.elementTag);
      this.state = 'loaded';
    } catch (err) {
      this.state = 'error';
      this.errorMessage = err instanceof Error
        ? err.message
        : 'An unexpected error occurred while loading the micro-app.';
    }
  }

  private renderElement(tagName: string): void {
    const host = this.hostRef.nativeElement;
    host.innerHTML = '';
    const element = document.createElement(tagName);
    element.setAttribute('account-id', 'acc-1001');
    host.appendChild(element);
  }
}
```

Using the loader from any page component is a single line:

```html
<app-microapp-loader microappName="statement-analysis"></app-microapp-loader>
```

The page component does not import the micro-app, does not know its version, does not reference its bundle URL. It passes a name string. The loader resolves everything else through the manifest. If the analysis micro-app is upgraded to v2.0.0, the page component's code does not change.

The `CUSTOM_ELEMENTS_SCHEMA` import tells Angular's template compiler to allow unknown HTML elements, the `<mf-statement-analysis>` tag that the loader will create dynamically. Without this, Angular would reject the unknown tag at compile time, which would defeat the entire purpose of runtime discovery.

## Web Components: The Integration Contract

Each micro-app is a standalone Angular application packaged as a Web Component. The bridge is Angular Elements, a library that wraps Angular components as custom HTML elements.

### Bootstrapping a Micro-App

The micro-app's `main.ts` is the entry point. When the browser loads this script, it creates an Angular application, wraps the root component as a custom element, and registers it:

```typescript
import { createApplication } from '@angular/platform-browser';
import { createCustomElement } from '@angular/elements';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

(async () => {
  const appRef = await createApplication(appConfig);

  const analysisElement = createCustomElement(AppComponent, {
    injector: appRef.injector,
  });

  customElements.define('mf-statement-analysis', analysisElement);
})();
```

Three things happen here:

1. `createApplication(appConfig)` bootstraps a full Angular application with dependency injection, HTTP client, change detection, everything a normal Angular app has.
2. `createCustomElement(AppComponent, { injector })` wraps the root component as a Web Component. The injector allows the component to use Angular's DI system (HttpClient, services, etc.).
3. `customElements.define('mf-statement-analysis', ...)` registers the custom element in the browser's `CustomElementRegistry`. From this point, any `<mf-statement-analysis>` element in the DOM will be an instance of this Angular component.

The custom element is framework-agnostic at the integration boundary. The shell creates it with `document.createElement('mf-statement-analysis')`, standard DOM API. It could equally be created from React, Vue, Svelte, or plain HTML. The fact that it is Angular internally is an implementation detail invisible to the consumer.

### The Micro-App Component

The statement-analysis micro-app is a complete, self-contained Angular component that fetches data from the analysis-service and renders spending insights:

```typescript
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="analysis-container" [class.v2]="isV2">
      <div class="header">
        <h2 class="title">
          {{ isV2 ? 'Statement Analysis v2' : 'Statement Analysis' }}
          <span *ngIf="isV2" class="v2-badge">v2</span>
        </h2>
        <button class="run-btn" (click)="runAnalysis()" [disabled]="runningAnalysis">
          {{ runningAnalysis ? 'Analyzing...' : 'Run Analysis' }}
        </button>
      </div>

      <div *ngIf="!loading && !error && summary">
        <!-- Category Breakdown -->
        <div class="section">
          <h3 class="section-title">Spending by Category</h3>
          <table class="category-table">
            ...
          </table>
        </div>

        <!-- Top Merchants (v2 only) -->
        <div *ngIf="isV2 && summary.topMerchants?.length > 0" class="section">
          <h3 class="section-title">Top Merchants</h3>
          ...
        </div>

        <!-- Insights -->
        <div *ngIf="summary.insights?.length > 0" class="section">
          <h3 class="section-title">Insights</h3>
          ...
        </div>
      </div>
    </div>
  `
})
export class AppComponent implements OnInit {
  private readonly baseUrl = 'http://localhost:8083/accounts/acc-1001/analysis';
  private readonly statementId = 'stmt-2025-12';

  isV2 = environment.version === 2;
  summary: AnalysisSummary | null = null;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadSummary();
  }

  loadSummary(): void {
    this.http.get<AnalysisSummary>(
      `${this.baseUrl}/summary?statementId=${this.statementId}`
    ).subscribe({
      next: (data) => { this.summary = data; },
      error: (err) => { this.error = 'Failed to load analysis summary.'; },
    });
  }
}
```

The component is fully self-contained. It has its own `HttpClient` instance, its own styling, its own data fetching. It calls the analysis-service directly, the same service we built in Part 2. The micro-app and the backend service are developed and deployed independently, but they share a contract: the `AnalysisSummary` JSON structure.

Notice the `isV2 = environment.version === 2` check. This is how version differentiation works within the component. The v2 build includes a "Top Merchants" section and a version badge that v1 does not have. Same component, different features, controlled by the build configuration.

## Version Switching: The Paradigm Shift

This is where the architecture reveals its power. Let's walk through a live version update.

### Step 1: Two Versions Exist on the CDN

The build pipeline produces both versions:

```bash
# Build v1
cd mobile/microapps/statement-analysis
npx ng build --configuration production
# → dist/statement-analysis/browser/

# Build v2 (uses environment.v2.ts with version: 2)
npx ng build --configuration v2
# → dist/statement-analysis-v2/browser/
```

The v2 build configuration uses Angular's file replacement to swap the environment file:

```json
{
  "configurations": {
    "production": {
      "outputHashing": "none",
      "optimization": true
    },
    "v2": {
      "outputHashing": "none",
      "optimization": true,
      "fileReplacements": [
        {
          "replace": "src/environments/environment.ts",
          "with": "src/environments/environment.v2.ts"
        }
      ]
    }
  }
}
```

The publish script copies both versions to the CDN:

```bash
publish_microapp() {
    local name=$1
    local version=$2
    local source_dir=$3
    local target_dir="$CDN_DIR/$name/$version"

    mkdir -p "$target_dir"
    cp "$source_dir"/*.js "$target_dir/"

    # Ensure main.js exists as the entry point
    if [ ! -f "$target_dir/main.js" ]; then
        local largest=$(ls -S "$target_dir"/*.js | head -1)
        cp "$largest" "$target_dir/main.js"
    fi
}

publish_microapp "statement-analysis" "1.0.0" \
    "$MICROAPPS_DIR/statement-analysis/dist/statement-analysis/browser"

publish_microapp "statement-analysis" "2.0.0" \
    "$MICROAPPS_DIR/statement-analysis/dist/statement-analysis-v2/browser"
```

After publishing, the CDN has:

```
www/statement-analysis/
├── 1.0.0/main.js    (v1 bundle)
└── 2.0.0/main.js    (v2 bundle with Top Merchants)
```

### Step 2: The Manifest Points to v1

Initially, the manifest references v1.0.0:

```json
{
  "name": "statement-analysis",
  "version": "1.0.0",
  "remoteEntry": "http://localhost:8090/statement-analysis/1.0.0/main.js",
  "elementTag": "mf-statement-analysis"
}
```

Users see the v1 UI: category table and insights, no merchants section.

### Step 3: Edit the Manifest

To activate v2, edit `manifest.json`, change two fields:

```json
{
  "name": "statement-analysis",
  "version": "2.0.0",
  "remoteEntry": "http://localhost:8090/statement-analysis/2.0.0/main.js",
  "elementTag": "mf-statement-analysis"
}
```

### Step 4: Users See v2

The next time a user navigates to the Analysis tab (or refreshes the page), the shell fetches the updated manifest, sees v2.0.0, loads the new bundle from the CDN, and renders the v2 custom element. The "Top Merchants" section appears. The v2 badge shows.

No app store review. No coordinated release. No rebuild of the shell application. No risk to the statement-details or recommendations micro-apps.

**This is blue-green deployment for the frontend.** Both versions are deployed. The manifest is the traffic router. Rolling back is editing the manifest back to v1.0.0.

## What This Architecture Eliminates

Let's compare with the traditional approach:

| Concern | Monolithic Frontend | This Architecture |
|---------|-------------------|-------------------|
| **Release coupling** | All teams release together | Each micro-app releases independently |
| **Build coupling** | Single build pipeline | Independent builds per micro-app |
| **Version coupling** | One version in production | Multiple versions coexist on CDN |
| **Framework coupling** | All components use same framework version | Each micro-app can use any framework |
| **Failure coupling** | One broken component breaks the app | One broken micro-app shows an error card; others work |
| **Discovery** | Compile-time imports | Runtime manifest lookup |
| **Update mechanism** | App store / full redeploy | Edit manifest, refresh browser |

The pattern also differs from webpack Module Federation in a significant way. Module Federation operates at build time, the shell's webpack configuration declares which remotes it expects, and the shared dependency negotiation happens during bundling. If a remote changes its exposed module signature, the shell must be rebuilt.

Our manifest-driven approach operates at runtime. The shell has zero compile-time knowledge of micro-apps. It reads a manifest, injects a script tag, waits for a custom element. The integration contract is a HTML tag name and a set of attributes, the most stable, framework-agnostic interface possible.

## The Full Independence Stack

Across this series, we have built independence at every layer:

```
┌─────────────────────────────────────────────────────────┐
│  FRONTEND LAYER                                         │
│  Manifest → CDN → Web Component                         │
│  Each micro-app: independent build, version, deploy     │
├─────────────────────────────────────────────────────────┤
│  API LAYER                                              │
│  HttpClientProvider → service name resolution            │
│  Each service: independent endpoint, no shared URLs     │
├─────────────────────────────────────────────────────────┤
│  COMPUTATION LAYER                                      │
│  EventSourcedEntity → Actor Model                       │
│  Each entity: independent state, addressing, recovery   │
├─────────────────────────────────────────────────────────┤
│  PERSISTENCE LAYER                                      │
│  Event Journal → Immutable append-only log              │
│  Each entity: independent event stream, replay, audit   │
└─────────────────────────────────────────────────────────┘
```

**Persistence**, Events are the source of truth. Each entity has its own event stream. State is derived, not stored. New projections can be built retroactively from the event log.

**Computation**, Each entity is an independently addressable actor. It processes commands sequentially, emits events, and can be recovered on any node by replaying its journal. Failure of one entity does not affect others.

**API**, Services discover each other by name. No URLs, no environment variables, no service registry. The platform handles TLS, load balancing, and routing. A service can be redeployed without its consumers knowing.

**Frontend**, Micro-apps are discovered at runtime through a manifest. Each is a Web Component loaded from a CDN. Version updates happen by editing the manifest. The shell has no compile-time dependency on any micro-app.

At every layer, the same principle holds: **consumers know only a name; the infrastructure resolves it to a concrete implementation.** The statement-service knows entity IDs. The analysis-service knows service names. The shell knows micro-app names. Location, version, and implementation are resolved at runtime, not compiled in.

## Design Decisions Worth Examining

### Why Not Module Federation?

Webpack Module Federation is the current industry standard for micro-frontends in JavaScript. It provides shared dependencies, lazy loading, and type safety across micro-app boundaries. It is a capable system.

We chose not to use it for three reasons:

First, Module Federation creates build-tool coupling. The shell and all micro-apps must use compatible webpack versions. Upgrading webpack in one micro-app can break others. This is a form of the same coupling we spent four posts eliminating on the backend.

Second, Module Federation operates at the JavaScript module level. The shell imports modules from remotes. This creates a tighter coupling than HTML elements, if a remote changes its exported module shape, the shell must be updated.

Third, our approach uses browser standards exclusively. `customElements.define`, `document.createElement`, `<script>` tags, these APIs have been stable for years and will remain stable. They work identically in Chrome, Firefox, Safari, and Edge. They do not require a build tool.

The trade-off is real: we do not get shared dependencies (each micro-app bundles its own Angular, RxJS, etc., increasing total download size) and we do not get type safety across the boundary. For our use case, small, focused micro-apps with independent concerns, this trade-off is worth the decoupling.

### Why Web Components?

Web Components provide three things that matter for micro-frontends:

**Encapsulation.** Each micro-app's DOM and styles are isolated. CSS from the statement-details micro-app cannot bleed into the analysis micro-app. This is Shadow DOM, a browser feature, not a framework feature.

**Standardization.** Custom elements are a W3C specification. Any framework can create them (Angular Elements, React's `createRoot`, Vue's `defineCustomElement`, Lit). Any framework can consume them (`document.createElement`). The integration boundary is framework-agnostic.

**Simplicity.** A custom element is an HTML tag. You create it, set attributes on it, append it to the DOM. There is no import system, no module resolution, no shared context. It is the simplest possible integration mechanism.

### Failure Isolation

When a micro-app fails to load, the CDN is down, the script has a syntax error, the custom element times out, the `MicroAppLoaderComponent` catches the error and displays a retry button. The rest of the application continues working. The statements tab might fail while the recommendations tab works perfectly.

This is the UI equivalent of the backend's entity-level failure isolation. A crashed entity does not bring down the service. A failed micro-app does not bring down the shell.

## Series Recap

Across these four posts, we built a microservices system that achieves independence at every layer:

**[Part 1: Event Sourcing & CQRS]({{< ref "/blog/akka/event-sourcing-cqrs-with-akka" >}})**, Events as the source of truth. `EventSourcedEntity` for immutable state management. CQRS views for read-optimized projections. State as a derived value, a left fold over the event log.

**[Part 2: Cross-Service Communication & Agentic AI]({{< ref "/blog/akka/cross-service-communication-agentic-ai" >}})**, Platform-managed service discovery by name. Dual-mode analysis with deterministic heuristics alongside an LLM-powered Akka Agent. AI as a peer component with the same contracts as every other service.

**[Part 3: Deployment, Resilience & Multi-Region]({{< ref "/blog/akka/deployment-resilience-multi-region" >}})**, Zero-config deployment. Entity distribution and failure recovery through event replay. Multi-region replication where event-sourced entities become globally distributed.

**Part 4: Micro-Frontends**, Manifest-driven micro-app discovery. Web Components as the integration contract. Versioned CDN delivery with live version switching. The frontend decoupled as thoroughly as the backend.

The architectural choices compound. Event sourcing enables fearless deployment, because state is replayed, not migrated. The actor model enables entity-level distribution, because each entity is independently addressable and recoverable. Platform-managed discovery eliminates configuration, because consumers express intent rather than mechanism. Micro-frontends extend independence to the UI, because the manifest decouples what exists from where it lives.

Together, these form a system that is independently deployable from database event to UI pixel. Each team ships on their own cadence. Each component fails in isolation. Each version coexists with its predecessors. History is never lost. And the only addressing mechanism, from entity to service to micro-app, is a name.

The [complete source code](https://github.com/PradeepLoganathan/microsvs-microapp) is available on GitHub, including all four backend services, the mobile shell, the micro-apps, the platform services, build scripts, and deployment configurations.
