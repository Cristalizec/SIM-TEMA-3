
package com.example.supermarketqueuesimulator.entity;

import java.time.LocalDateTime;

public class Simulation {

    private long id;
    private String method;
    private int numberOfCustomers;
    private int numberOfCashiers;
    private double averageWait;
    private double averageService;
    private double totalTime;
    private LocalDateTime createdAt;

    // Empty constructor
    public Simulation() {
    }

    // Constructor
    public Simulation(String method,
                      int numberOfCustomers,
                      int numberOfCashiers,
                      double averageWait,
                      double averageService,
                      double totalTime) {

        this.method = method;
        this.numberOfCustomers = numberOfCustomers;
        this.numberOfCashiers = numberOfCashiers;
        this.averageWait = averageWait;
        this.averageService = averageService;
        this.totalTime = totalTime;
        this.createdAt = LocalDateTime.now();
    }

    // Getters and Setters

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getMethod() {
        return method;
    }

    public void setMethod(String method) {
        this.method = method;
    }

    public int getNumberOfCustomers() {
        return numberOfCustomers;
    }

    public void setNumberOfCustomers(int numberOfCustomers) {
        this.numberOfCustomers = numberOfCustomers;
    }

    public int getNumberOfCashiers() {
        return numberOfCashiers;
    }

    public void setNumberOfCashiers(int numberOfCashiers) {
        this.numberOfCashiers = numberOfCashiers;
    }

    public double getAverageWait() {
        return averageWait;
    }

    public void setAverageWait(double averageWait) {
        this.averageWait = averageWait;
    }

    public double getAverageService() {
        return averageService;
    }

    public void setAverageService(double averageService) {
        this.averageService = averageService;
    }

    public double getTotalTime() {
        return totalTime;
    }

    public void setTotalTime(double totalTime) {
        this.totalTime = totalTime;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
