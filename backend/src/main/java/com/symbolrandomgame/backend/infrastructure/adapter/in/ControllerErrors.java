package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.exception.UseCaseException;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.function.Supplier;

final class ControllerErrors {
    private ControllerErrors() {}

    static <T> T translate(Supplier<T> operation) {
        try {
            return operation.get();
        } catch (UseCaseException exception) {
            throw response(exception);
        }
    }

    static void translate(Runnable operation) {
        try {
            operation.run();
        } catch (UseCaseException exception) {
            throw response(exception);
        }
    }

    private static ResponseStatusException response(UseCaseException exception) {
        return new ResponseStatusException(
                HttpStatus.valueOf(exception.status()),
                exception.getMessage()
        );
    }
}
