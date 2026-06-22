package com.company.erp.core.response;

import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

/**
 * Auto-wraps controller return values in {@link ApiResponse} so handlers can
 * return DTOs directly. Skips bodies already wrapped, actuator/openapi paths,
 * and raw String / byte bodies (file downloads etc.).
 */
@RestControllerAdvice(basePackages = "com.company.erp")
public class ResponseEnvelopeAdvice implements ResponseBodyAdvice<Object> {

    @Override
    public boolean supports(MethodParameter returnType,
                            Class<? extends HttpMessageConverter<?>> converterType) {
        return !ApiResponse.class.isAssignableFrom(returnType.getParameterType());
    }

    @Override
    public Object beforeBodyWrite(Object body,
                                  MethodParameter returnType,
                                  MediaType selectedContentType,
                                  Class<? extends HttpMessageConverter<?>> selectedConverterType,
                                  ServerHttpRequest request,
                                  ServerHttpResponse response) {
        String path = request.getURI().getPath();
        if (path.startsWith("/actuator")
                || path.startsWith("/v3/api-docs")
                || path.startsWith("/docs")
                || path.startsWith("/swagger-ui")
                || path.endsWith("/error")) {
            return body;
        }
        if (body instanceof ApiResponse<?>)        return body;
        if (body instanceof String)                return body;
        if (body instanceof byte[])                return body;
        return ApiResponse.ok(body);
    }
}
