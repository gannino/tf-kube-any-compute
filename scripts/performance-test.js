// ============================================================================
// K6 Performance Tests for tf-kube-any-compute Infrastructure
// ============================================================================
//
// Load testing for deployed services to ensure performance standards
// Run with: k6 run scripts/performance-test.js
//
// Test scenarios:
// - Traefik ingress performance
// - Grafana dashboard loading
// - Consul API response times
// - Vault API performance (if unsealed)
// - Service discovery latency
//
// Requirements:
// - k6 (https://k6.io/)
// - Deployed infrastructure with ingress endpoints
//
// ============================================================================

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend, Rate } from 'k6/metrics';

// Custom metrics
const httpReqFailed = new Rate('http_req_failed');
const httpReqDuration = new Trend('http_req_duration');
const httpReqs = new Counter('http_reqs');

// Test configuration
export const options = {
  stages: [
    // Warm up
    { duration: '30s', target: 5 },
    // Normal load
    { duration: '2m', target: 10 },
    // Peak load
    { duration: '1m', target: 20 },
    // Cool down
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    // 95% of requests should complete within 2s
    http_req_duration: ['p(95)<2000'],
    // Error rate should be less than 5%
    http_req_failed: ['rate<0.05'],
    // Average response time should be less than 500ms
    'http_req_duration{type:api}': ['avg<500'],
    // Dashboard loads should complete within 5s
    'http_req_duration{type:dashboard}': ['p(95)<5000'],
  },
};

// Configuration - Update these URLs based on your deployment
const config = {
  // Base domain from terraform.tfvars
  baseDomain: __ENV.BASE_DOMAIN || 'prod.k3s.annino.cloud',

  // Service endpoints
  endpoints: {
    traefik: __ENV.TRAEFIK_URL || 'http://traefik.prod.k3s.annino.cloud',
    grafana: __ENV.GRAFANA_URL || 'http://grafana.prod.k3s.annino.cloud',
    consul: __ENV.CONSUL_URL || 'http://consul.prod.k3s.annino.cloud',
    vault: __ENV.VAULT_URL || 'http://vault.prod.k3s.annino.cloud',
    prometheus: __ENV.PROMETHEUS_URL || 'http://prometheus.prod.k3s.annino.cloud',
    alertmanager: __ENV.ALERTMANAGER_URL || 'http://alertmanager.prod.k3s.annino.cloud',
  },

  // Test parameters
  timeout: '10s',
  userAgent: 'k6-performance-test/1.0',
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function makeRequest(url, options = {}, tags = {}) {
  const params = {
    timeout: config.timeout,
    headers: {
      'User-Agent': config.userAgent,
      ...options.headers,
    },
    tags: {
      name: url,
      ...tags,
    },
    ...options,
  };

  const response = http.get(url, params);

  // Record custom metrics
  httpReqs.add(1);
  httpReqFailed.add(response.status >= 400);
  httpReqDuration.add(response.timings.duration, { type: tags.type || 'general' });

  return response;
}

function checkResponse(response, expectedStatus = 200, checkContent = true) {
  const checks = {
    [`status is ${expectedStatus}`]: (r) => r.status === expectedStatus,
    'response time < 2s': (r) => r.timings.duration < 2000,
  };

  if (checkContent && expectedStatus === 200) {
    checks['response has content'] = (r) => r.body && r.body.length > 0;
  }

  return check(response, checks);
}

// ============================================================================
// TEST SCENARIOS
// ============================================================================

export default function () {
  // Distribute load across different test scenarios
  const scenarios = [
    testTraefikIngress,
    testGrafanaDashboard,
    testConsulAPI,
    testVaultHealth,
    testPrometheusMetrics,
    testServiceDiscovery,
  ];

  // Pick a random scenario for this VU iteration
  const scenario = scenarios[Math.floor(Math.random() * scenarios.length)];
  scenario();

  // Small delay between requests
  sleep(1);
}

// ============================================================================
// TRAEFIK INGRESS TESTS
// ============================================================================

function testTraefikIngress() {
  console.log('Testing Traefik ingress performance...');

  // Test Traefik dashboard endpoint
  const response = makeRequest(
    `${config.endpoints.traefik}/dashboard/`,
    {
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    },
    { type: 'ingress', service: 'traefik' }
  );

  checkResponse(response, 200);

  // Test API endpoint
  const apiResponse = makeRequest(
    `${config.endpoints.traefik}/api/overview`,
    {},
    { type: 'api', service: 'traefik' }
  );

  checkResponse(apiResponse, 200);

  // Verify JSON response
  if (apiResponse.status === 200) {
    try {
      const data = JSON.parse(apiResponse.body);
      check(data, {
        'has http router info': (d) => d.http && d.http.routers !== undefined,
        'has providers info': (d) => d.providers !== undefined,
      });
    } catch (e) {
      console.warn('Failed to parse Traefik API response as JSON');
    }
  }
}

// ============================================================================
// GRAFANA DASHBOARD TESTS
// ============================================================================

function testGrafanaDashboard() {
  console.log('Testing Grafana dashboard performance...');

  // Test Grafana login page
  const loginResponse = makeRequest(
    `${config.endpoints.grafana}/login`,
    {},
    { type: 'dashboard', service: 'grafana' }
  );

  checkResponse(loginResponse, 200);

  // Test API health endpoint
  const healthResponse = makeRequest(
    `${config.endpoints.grafana}/api/health`,
    {},
    { type: 'api', service: 'grafana' }
  );

  if (healthResponse.status === 200) {
    try {
      const health = JSON.parse(healthResponse.body);
      check(health, {
        'database is ok': (h) => h.database === 'ok',
        'version is present': (h) => h.version && h.version.length > 0,
      });
    } catch (e) {
      console.warn('Failed to parse Grafana health response');
    }
  }

  // Test metrics endpoint (if accessible)
  const metricsResponse = makeRequest(
    `${config.endpoints.grafana}/metrics`,
    {},
    { type: 'metrics', service: 'grafana' }
  );

  // Metrics endpoint might return 404 if not enabled, that's OK
  check(metricsResponse, {
    'metrics accessible or not enabled': (r) => r.status === 200 || r.status === 404,
  });
}

// ============================================================================
// CONSUL API TESTS
// ============================================================================

function testConsulAPI() {
  console.log('Testing Consul API performance...');

  // Test Consul UI
  const uiResponse = makeRequest(
    `${config.endpoints.consul}/ui/`,
    {},
    { type: 'dashboard', service: 'consul' }
  );

  checkResponse(uiResponse, 200);

  // Test health endpoint
  const healthResponse = makeRequest(
    `${config.endpoints.consul}/v1/status/leader`,
    {},
    { type: 'api', service: 'consul' }
  );

  if (healthResponse.status === 200) {
    check(healthResponse, {
      'has leader': (r) => r.body && r.body.length > 0,
      'leader format valid': (r) => r.body.includes(':'),
    });
  }

  // Test catalog services
  const servicesResponse = makeRequest(
    `${config.endpoints.consul}/v1/catalog/services`,
    {},
    { type: 'api', service: 'consul' }
  );

  if (servicesResponse.status === 200) {
    try {
      const services = JSON.parse(servicesResponse.body);
      check(services, {
        'services is object': (s) => typeof s === 'object',
        'has consul service': (s) => s.consul !== undefined,
      });
    } catch (e) {
      console.warn('Failed to parse Consul services response');
    }
  }
}

// ============================================================================
// VAULT HEALTH TESTS
// ============================================================================

function testVaultHealth() {
  console.log('Testing Vault health performance...');

  // Test Vault UI
  const uiResponse = makeRequest(
    `${config.endpoints.vault}/ui/`,
    {},
    { type: 'dashboard', service: 'vault' }
  );

  checkResponse(uiResponse, 200);

  // Test health endpoint (allows sealed/uninitialized status)
  const healthResponse = makeRequest(
    `${config.endpoints.vault}/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200`,
    {},
    { type: 'api', service: 'vault' }
  );

  // Health endpoint should return 200 even if sealed
  if (healthResponse.status === 200) {
    try {
      const health = JSON.parse(healthResponse.body);
      check(health, {
        'has initialized field': (h) => h.initialized !== undefined,
        'has sealed field': (h) => h.sealed !== undefined,
        'has version': (h) => h.version && h.version.length > 0,
      });
    } catch (e) {
      console.warn('Failed to parse Vault health response');
    }
  }

  // Test metrics endpoint (might be blocked if sealed)
  const metricsResponse = makeRequest(
    `${config.endpoints.vault}/v1/sys/metrics`,
    {},
    { type: 'metrics', service: 'vault' }
  );

  check(metricsResponse, {
    'metrics accessible or blocked': (r) => r.status === 200 || r.status === 403 || r.status === 503,
  });
}

// ============================================================================
// PROMETHEUS METRICS TESTS
// ============================================================================

function testPrometheusMetrics() {
  console.log('Testing Prometheus metrics performance...');

  // Test Prometheus UI
  const uiResponse = makeRequest(
    `${config.endpoints.prometheus}/graph`,
    {},
    { type: 'dashboard', service: 'prometheus' }
  );

  checkResponse(uiResponse, 200);

  // Test API status
  const statusResponse = makeRequest(
    `${config.endpoints.prometheus}/api/v1/status/config`,
    {},
    { type: 'api', service: 'prometheus' }
  );

  if (statusResponse.status === 200) {
    try {
      const status = JSON.parse(statusResponse.body);
      check(status, {
        'has status success': (s) => s.status === 'success',
        'has data': (s) => s.data !== undefined,
      });
    } catch (e) {
      console.warn('Failed to parse Prometheus status response');
    }
  }

  // Test simple query
  const queryResponse = makeRequest(
    `${config.endpoints.prometheus}/api/v1/query?query=up`,
    {},
    { type: 'query', service: 'prometheus' }
  );

  if (queryResponse.status === 200) {
    try {
      const query = JSON.parse(queryResponse.body);
      check(query, {
        'query successful': (q) => q.status === 'success',
        'has result data': (q) => q.data && q.data.result,
      });
    } catch (e) {
      console.warn('Failed to parse Prometheus query response');
    }
  }
}

// ============================================================================
// SERVICE DISCOVERY TESTS
// ============================================================================

function testServiceDiscovery() {
  console.log('Testing service discovery performance...');

  // Test multiple service endpoints to verify service discovery
  const services = [
    { name: 'grafana', url: config.endpoints.grafana },
    { name: 'consul', url: config.endpoints.consul },
    { name: 'prometheus', url: config.endpoints.prometheus },
  ];

  for (const service of services) {
    const response = makeRequest(
      service.url,
      { redirects: 0 }, // Don't follow redirects for this test
      { type: 'discovery', service: service.name }
    );

    check(response, {
      [`${service.name} service discoverable`]: (r) => r.status < 500,
      [`${service.name} response time acceptable`]: (r) => r.timings.duration < 1000,
    });
  }
}

// ============================================================================
// SETUP AND TEARDOWN
// ============================================================================

export function setup() {
  console.log('Starting performance tests for tf-kube-any-compute infrastructure');
  console.log(`Base domain: ${config.baseDomain}`);
  console.log('Endpoints:');
  for (const [service, url] of Object.entries(config.endpoints)) {
    console.log(`  ${service}: ${url}`);
  }
  console.log('');

  // Verify at least one endpoint is accessible
  const healthCheck = makeRequest(config.endpoints.traefik, { timeout: '5s' });
  if (healthCheck.status >= 500) {
    throw new Error('Infrastructure appears to be unavailable. Check deployment status.');
  }

  return { timestamp: new Date().toISOString() };
}

export function teardown(data) {
  console.log('');
  console.log('Performance test completed at:', new Date().toISOString());
  console.log('Test started at:', data.timestamp);

  // Summary will be automatically generated by k6
}
