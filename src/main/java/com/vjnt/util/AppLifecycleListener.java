package com.vjnt.util;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

/**
 * Cleans up process-wide resources when the web application stops or is
 * redeployed.
 *
 * Without this, the static HikariCP pool in {@link DatabaseConnection} keeps its
 * background threads (PoolEntryCreator / housekeeper) running after Tomcat has
 * stopped the context. Those threads then try to load JDBC driver classes
 * through the already-stopped WebappClassLoader and Tomcat logs:
 *
 *   java.lang.IllegalStateException: Illegal access: this web application
 *   instance has been stopped already. Could not load
 *   [com.mysql.cj.protocol.a.NativeCapabilities].
 *
 * Closing the pool in contextDestroyed() stops those threads cleanly first.
 */
@WebListener
public class AppLifecycleListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        // nothing to do — the pool initialises lazily on first use
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        DatabaseConnection.shutdown();
    }
}
