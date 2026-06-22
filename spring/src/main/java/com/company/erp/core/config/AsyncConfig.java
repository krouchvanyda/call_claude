package com.company.erp.core.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

/** Enables {@code @Async} so fire-and-forget tasks (FCM push, etc.) don't block the request thread. */
@Configuration
@EnableAsync
public class AsyncConfig {
}
