
package com.example.supermarketqueuesimulator.service;

import com.example.supermarketqueuesimulator.entity.Customer;
import com.example.supermarketqueuesimulator.entity.Simulation;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class SimulationService {

    private final Random random = new Random();

    // Average time between customer arrivals (minutes)
    private static final double MEAN_ARRIVAL = 2.0;

    // Average service time (minutes)
    private static final double MEAN_SERVICE = 4.0;

    // Inverse transform method
    private double inverseTransform(double mean) {

        double u = random.nextDouble();

        return -mean * Math.log(1.0 - u);
    }

    // Convolution method
    // Sum of two independent exponential variables
    private double convolution() {

        double x1 = inverseTransform(2.0);
        double x2 = inverseTransform(2.0);

        return x1 + x2;
    }

    // Composition method
    // Mixture of two exponential distributions
    private double composition() {

        double u = random.nextDouble();

        if (u < 0.75) {
            return inverseTransform(2.0);
        } else {
            return inverseTransform(10.0);
        }
    }

    // Generate random service time
    private double generateServiceTime(String method) {

        return switch (method) {

            case "Transformada inversa" ->
                    inverseTransform(MEAN_SERVICE);

            case "Convolución" ->
                    convolution();

            case "Composición" ->
                    composition();

            default -> throw new IllegalArgumentException(
                    "Invalid simulation method: " + method
            );
        };
    }

    // Generate complete supermarket simulation
    public SimulationResult generateSimulation(
            String method,
            int numberOfCustomers,
            int numberOfCashiers) {

        if (numberOfCustomers <= 0) {
            throw new IllegalArgumentException(
                    "Number of customers must be greater than zero");
        }

        if (numberOfCashiers <= 0) {
            throw new IllegalArgumentException(
                    "Number of cashiers must be greater than zero");
        }

        List<Customer> customers = new ArrayList<>();

        // Track when each cashier becomes available
        double[] cashierAvailable =
                new double[numberOfCashiers];

        double currentArrival = 0;
        double totalWaiting = 0;
        double totalService = 0;
        double totalTime = 0;

        for (int i = 1; i <= numberOfCustomers; i++) {

            // Generate customer arrival
            double interArrival =
                    inverseTransform(MEAN_ARRIVAL);

            currentArrival += interArrival;

            // Generate service time
            double serviceTime =
                    generateServiceTime(method);

            // Find earliest available cashier
            int selectedCashier = 0;

            for (int j = 1; j < numberOfCashiers; j++) {

                if (cashierAvailable[j] <
                        cashierAvailable[selectedCashier]) {

                    selectedCashier = j;
                }
            }

            // Calculate customer times
            double startTime = Math.max(
                    currentArrival,
                    cashierAvailable[selectedCashier]
            );

            double waitTime =
                    startTime - currentArrival;

            double departureTime =
                    startTime + serviceTime;

            // Update cashier availability
            cashierAvailable[selectedCashier] =
                    departureTime;

            // Create customer
            Customer customer = new Customer(
                    i,
                    currentArrival,
                    serviceTime,
                    startTime,
                    waitTime,
                    departureTime,
                    selectedCashier + 1
            );

            customers.add(customer);

            // Update statistics
            totalWaiting += waitTime;
            totalService += serviceTime;

            totalTime = Math.max(
                    totalTime,
                    departureTime
            );
        }

        // Calculate averages
        double averageWait =
                totalWaiting / numberOfCustomers;

        double averageService =
                totalService / numberOfCustomers;

        // Create simulation entity
        Simulation simulation = new Simulation(
                method,
                numberOfCustomers,
                numberOfCashiers,
                averageWait,
                averageService,
                totalTime
        );

        return new SimulationResult(
                simulation,
                customers
        );
    }

    // Return simulation and generated customers
    public record SimulationResult(
            Simulation simulation,
            List<Customer> customers
    ) {
    }
}
