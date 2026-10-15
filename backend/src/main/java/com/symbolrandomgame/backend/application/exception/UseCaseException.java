package com.symbolrandomgame.backend.application.exception;

public class UseCaseException extends RuntimeException {
    private final int status;

    public UseCaseException(int status, String message) {
        super(message);
        this.status = status;
    }

    public int status() {
        return status;
    }
}
