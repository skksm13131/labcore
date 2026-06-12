package com.hwz.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer.addPathPrefix("/api", clazz -> clazz.isAnnotationPresent(RestController.class));
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/lite/lab/").setViewName("forward:/lite/lab/index.html");
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // API路径的CORS配置 - 允许具体域名
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:5173", "http://127.0.0.1:5173", "http://localhost:8080", "http://127.0.0.1:8080", "https://app.apifox.com", "http://10.206.88.228:5173", "http://10.14.18.152:5173", "http://10.12.52.134", "http://10.12.52.134:8080", "https://labcore.henu.edu.cn", "http://labcore.henu.edu.cn")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);

        // 静态资源的CORS配置
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:5173", "http://127.0.0.1:5173", "http://localhost:8080", "http://127.0.0.1:8080", "https://app.apifox.com", "http://10.206.88.228:5173", "http://10.14.18.152:5173", "http://10.12.52.134", "http://10.12.52.134:8080", "https://labcore.henu.edu.cn", "http://labcore.henu.edu.cn")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(false)
                .maxAge(3600);
    }
}
