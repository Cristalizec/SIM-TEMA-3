
package com.example.supermarketqueuesimulator.entity;

public class Customer {

    private long id;
    private long simulationId;

    private int customerNumber;
    private double arrivalTime;
    private double serviceTime;
    private double startTime;
    private double waitTime;
    private double departureTime;
    private int cashierNumber;

    // Empty constructor
    public Customer() {
    }

    // Constructor
    public Customer(int customerNumber,
                    double arrivalTime,
                    double serviceTime,
                    double startTime,
                    double waitTime,
                    double departureTime,
                    int cashierNumber) {

        this.customerNumber = customerNumber;
        this.arrivalTime = arrivalTime;
        this.serviceTime = serviceTime;
        this.startTime = startTime;
        this.waitTime = waitTime;
        this.departureTime = departureTime;
        this.cashierNumber = cashierNumber;
    }

    // Getters and Setters

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getSimulationId() {
        return simulationId;
    }

    public void setSimulationId(long simulationId) {
        this.simulationId = simulationId;
    }

    public int getCustomerNumber() {
        return customerNumber;
    }

    public void setCustomerNumber(int customerNumber) {
        this.customerNumber = customerNumber;
    }

    public double getArrivalTime() {
        return arrivalTime;
    }

    public void setArrivalTime(double arrivalTime) {
        this.arrivalTime = arrivalTime;
    }

    public double getServiceTime() {
        return serviceTime;
    }

    public void setServiceTime(double serviceTime) {
        this.serviceTime = serviceTime;
    }

    public double getStartTime() {
        return startTime;
    }

    public void setStartTime(double startTime) {
        this.startTime = startTime;
    }

    public double getWaitTime() {
        return waitTime;
    }

    public void setWaitTime(double waitTime) {
        this.waitTime = waitTime;
    }

    public double getDepartureTime() {
        return departureTime;
    }

    public void setDepartureTime(double departureTime) {
        this.departureTime = departureTime;
    }

    public int getCashierNumber() {
        return cashierNumber;
    }

    public void setCashierNumber(int cashierNumber) {
        this.cashierNumber = cashierNumber;
    }
}
