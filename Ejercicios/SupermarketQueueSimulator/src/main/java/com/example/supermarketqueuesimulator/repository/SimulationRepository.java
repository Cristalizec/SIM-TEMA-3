
package com.example.supermarketqueuesimulator.repository;

import com.example.supermarketqueuesimulator.config.Database;
import com.example.supermarketqueuesimulator.entity.Customer;
import com.example.supermarketqueuesimulator.entity.Simulation;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SimulationRepository {

    // Save simulation and customers
    public void saveSimulation(
            Simulation simulation,
            List<Customer> customers) throws SQLException {

        String simulationSQL = """
                INSERT INTO simulations (
                    method,
                    number_of_customers,
                    number_of_cashiers,
                    average_wait,
                    average_service,
                    total_time
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """;

        String customerSQL = """
                INSERT INTO customers (
                    simulation_id,
                    customer_number,
                    arrival_time,
                    service_time,
                    start_time,
                    wait_time,
                    departure_time,
                    cashier_number
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """;

        try (Connection connection = Database.getConnection()) {

            connection.setAutoCommit(false);

            try {
                long simulationId;

                // Insert simulation
                try (PreparedStatement statement =
                             connection.prepareStatement(
                                     simulationSQL,
                                     Statement.RETURN_GENERATED_KEYS)) {

                    statement.setString(1, simulation.getMethod());
                    statement.setInt(2, simulation.getNumberOfCustomers());
                    statement.setInt(3, simulation.getNumberOfCashiers());
                    statement.setDouble(4, simulation.getAverageWait());
                    statement.setDouble(5, simulation.getAverageService());
                    statement.setDouble(6, simulation.getTotalTime());

                    statement.executeUpdate();

                    try (ResultSet keys = statement.getGeneratedKeys()) {
                        if (!keys.next()) {
                            throw new SQLException(
                                    "Simulation ID was not generated");
                        }

                        simulationId = keys.getLong(1);
                    }
                }

                // Insert customers
                try (PreparedStatement statement =
                             connection.prepareStatement(customerSQL)) {

                    for (Customer customer : customers) {

                        statement.setLong(1, simulationId);
                        statement.setInt(2, customer.getCustomerNumber());
                        statement.setDouble(3, customer.getArrivalTime());
                        statement.setDouble(4, customer.getServiceTime());
                        statement.setDouble(5, customer.getStartTime());
                        statement.setDouble(6, customer.getWaitTime());
                        statement.setDouble(7, customer.getDepartureTime());
                        statement.setInt(8, customer.getCashierNumber());

                        statement.addBatch();
                    }

                    statement.executeBatch();
                }

                connection.commit();

                simulation.setId(simulationId);

                for (Customer customer : customers) {
                    customer.setSimulationId(simulationId);
                }

                System.out.println(
                        "Simulation saved successfully! ID: "
                                + simulationId);

            } catch (SQLException e) {
                connection.rollback();
                throw e;
            }
        }
    }

    // Get all simulations
    public List<Simulation> getAllSimulations()
            throws SQLException {

        List<Simulation> simulations = new ArrayList<>();

        String sql = """
                SELECT *
                FROM simulations
                ORDER BY id DESC
                """;

        try (Connection connection = Database.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {

            while (result.next()) {

                Simulation simulation = new Simulation();

                simulation.setId(result.getLong("id"));
                simulation.setMethod(result.getString("method"));

                simulation.setNumberOfCustomers(
                        result.getInt("number_of_customers"));

                simulation.setNumberOfCashiers(
                        result.getInt("number_of_cashiers"));

                simulation.setAverageWait(
                        result.getDouble("average_wait"));

                simulation.setAverageService(
                        result.getDouble("average_service"));

                simulation.setTotalTime(
                        result.getDouble("total_time"));

                Timestamp timestamp =
                        result.getTimestamp("created_at");

                if (timestamp != null) {
                    simulation.setCreatedAt(
                            timestamp.toLocalDateTime());
                }

                simulations.add(simulation);
            }
        }

        return simulations;
    }

    // Get customers by simulation ID
    public List<Customer> getCustomersBySimulationId(
            long simulationId) throws SQLException {

        List<Customer> customers = new ArrayList<>();

        String sql = """
                SELECT *
                FROM customers
                WHERE simulation_id = ?
                ORDER BY customer_number ASC
                """;

        try (Connection connection = Database.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setLong(1, simulationId);

            try (ResultSet result = statement.executeQuery()) {

                while (result.next()) {

                    Customer customer = new Customer();

                    customer.setId(result.getLong("id"));

                    customer.setSimulationId(
                            result.getLong("simulation_id"));

                    customer.setCustomerNumber(
                            result.getInt("customer_number"));

                    customer.setArrivalTime(
                            result.getDouble("arrival_time"));

                    customer.setServiceTime(
                            result.getDouble("service_time"));

                    customer.setStartTime(
                            result.getDouble("start_time"));

                    customer.setWaitTime(
                            result.getDouble("wait_time"));

                    customer.setDepartureTime(
                            result.getDouble("departure_time"));

                    customer.setCashierNumber(
                            result.getInt("cashier_number"));

                    customers.add(customer);
                }
            }
        }

        return customers;
    }
}
