package lab;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.management.ManagementFactory;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class DirectMemoryProbeApp {
  private static final List<ByteBuffer> DIRECT_BUFFERS = new ArrayList<>();

  public static void main(String[] args) throws Exception {
    int port = Integer.parseInt(getEnv("PORT", "8080"));
    int directTargetMb = Integer.parseInt(getEnv("DIRECT_TARGET_MB", "230"));
    int chunkMb = Integer.parseInt(getEnv("DIRECT_CHUNK_MB", "4"));
    int sleepMs = Integer.parseInt(getEnv("ALLOC_SLEEP_MS", "100"));

    printStartupInfo(port, directTargetMb, chunkMb, sleepMs);
    startHttpServer(port);
    allocateDirectMemory(directTargetMb, chunkMb, sleepMs);

    while (true) {
      Thread.sleep(5000);
      logRuntime("steady-state");
    }
  }

  private static void printStartupInfo(int port, int directTargetMb, int chunkMb, int sleepMs) {
    System.out.println("=== DirectMemoryProbeApp startup ===");
    System.out.println("time=" + Instant.now());
    System.out.println("pid=" + ProcessHandle.current().pid());
    System.out.println("port=" + port);
    System.out.println("DIRECT_TARGET_MB=" + directTargetMb);
    System.out.println("DIRECT_CHUNK_MB=" + chunkMb);
    System.out.println("ALLOC_SLEEP_MS=" + sleepMs);
    System.out.println("jvmArgs=" + ManagementFactory.getRuntimeMXBean().getInputArguments());
  }

  private static void startHttpServer(int port) throws IOException {
    HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
    server.createContext("/health", exchange -> {
      byte[] body = "ok".getBytes();
      exchange.sendResponseHeaders(200, body.length);
      try (OutputStream os = exchange.getResponseBody()) {
        os.write(body);
      }
    });
    server.createContext("/metrics", exchange -> {
      Runtime rt = Runtime.getRuntime();
      String body = String.format(
          "heap_used_bytes %d\nheap_max_bytes %d\ndirect_buffers %d\n",
          rt.totalMemory() - rt.freeMemory(),
          rt.maxMemory(),
          DIRECT_BUFFERS.size());
      byte[] bytes = body.getBytes();
      exchange.sendResponseHeaders(200, bytes.length);
      try (OutputStream os = exchange.getResponseBody()) {
        os.write(bytes);
      }
    });
    server.start();
  }

  private static void allocateDirectMemory(int directTargetMb, int chunkMb, int sleepMs)
      throws InterruptedException {
    int chunks = directTargetMb / chunkMb;
    for (int i = 0; i < chunks; i++) {
      ByteBuffer buffer = ByteBuffer.allocateDirect(chunkMb * 1024 * 1024);
      buffer.putInt(0, i);
      DIRECT_BUFFERS.add(buffer);

      if (i % 4 == 0) {
        logRuntime("alloc-step-" + i);
      }
      Thread.sleep(sleepMs);
    }

    logRuntime("alloc-finished");
  }

  private static void logRuntime(String phase) {
    Runtime rt = Runtime.getRuntime();
    long heapUsed = rt.totalMemory() - rt.freeMemory();
    System.out.printf("phase=%s heapUsedMB=%d heapMaxMB=%d directChunks=%d%n",
        phase,
        heapUsed / 1024 / 1024,
        rt.maxMemory() / 1024 / 1024,
        DIRECT_BUFFERS.size());
  }

  private static String getEnv(String key, String def) {
    String value = System.getenv(key);
    return value == null || value.isBlank() ? def : value;
  }
}
