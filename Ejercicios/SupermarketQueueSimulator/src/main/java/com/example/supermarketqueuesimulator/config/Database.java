
package com.example.supermarketqueuesimulator.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class Database {

    // PostgreSQL configuration
    private static final String URL =
            "jdbc:postgresql://localhost:5432/supermarket_simulator_db";

    private static final String USER = "postgres";
    private static final String PASSWORD = "";

    // Connect to PostgreSQL
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    // Create database tables automatically
    public static void initializeDatabase() throws SQLException {

        String simulationsTable = """
                CREATE TABLE IF NOT EXISTS simulations (
                    id BIGSERIAL PRIMARY KEY,
                    method VARCHAR(50) NOT NULL,
                    number_of_customers INTEGER NOT NULL,
                    number_of_cashiers INTEGER NOT NULL,
                    average_wait DOUBLE PRECISION,
                    average_service DOUBLE PRECISION,
                    total_time DOUBLE PRECISION,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """;

        String customersTable = """
                CREATE TABLE IF NOT EXISTS customers (
                    id BIGSERIAL PRIMARY KEY,
                    simulation_id BIGINT NOT NULL,
                    customer_number INTEGER NOT NULL,
                    arrival_time DOUBLE PRECISION NOT NULL,
                    service_time DOUBLE PRECISION NOT NULL,
                    start_time DOUBLE PRECISION NOT NULL,
                    wait_time DOUBLE PRECISION NOT NULL,
                    departure_time DOUBLE PRECISION NOT NULL,
                    cashier_number INTEGER NOT NULL,

                    FOREIGN KEY (simulation_id)
                    REFERENCES simulations(id)
                    ON DELETE CASCADE
                );
                """;

        try (Connection connection = getConnection();
             Statement statement = connection.createStatement()) {

            statement.executeUpdate(simulationsTable);
            statement.executeUpdate(customersTable);

            System.out.println("Database connected successfully!");
            System.out.println("Tables created successfully!");

        }
    }
}
