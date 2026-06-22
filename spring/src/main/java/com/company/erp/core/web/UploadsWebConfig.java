package com.company.erp.core.web;

import com.company.erp.core.config.AppProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class UploadsWebConfig implements WebMvcConfigurer {

    private final AppProperties props;

    public UploadsWebConfig(AppProperties props) {
        this.props = props;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path absolute = Paths.get(props.uploads().avatar().dir()).toAbsolutePath().normalize();
        String pattern = trimTrailingSlash(props.uploads().avatar().publicBaseUrl()) + "/**";
        registry.addResourceHandler(pattern)
                .addResourceLocations("file:" + absolute + "/");
    }

    private static String trimTrailingSlash(String s) {
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }
}
