
package com.example.supermarketqueuesimulator.controller;

import com.example.supermarketqueuesimulator.config.Database;
import com.example.supermarketqueuesimulator.entity.Customer;
import com.example.supermarketqueuesimulator.entity.Simulation;
import com.example.supermarketqueuesimulator.repository.SimulationRepository;
import com.example.supermarketqueuesimulator.service.SimulationService;

import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.beans.property.ReadOnlyStringWrapper;
import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.XYChart;
import javafx.scene.control.*;

import java.sql.SQLException;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

public class SimulatorController {

    // Simulation controls
    @FXML private TextField customersField;
    @FXML private TextField cashiersField;
    @FXML private ComboBox<String> methodCombo;

    // Customer table
    @FXML private TableView<Customer> customerTable;

    @FXML private TableColumn<Customer, Integer> customerNumberColumn;
    @FXML private TableColumn<Customer, Double> arrivalTimeColumn;
    @FXML private TableColumn<Customer, Double> serviceTimeColumn;
    @FXML private TableColumn<Customer, Double> startTimeColumn;
    @FXML private TableColumn<Customer, Double> waitTimeColumn;
    @FXML private TableColumn<Customer, Double> departureTimeColumn;
    @FXML private TableColumn<Customer, Integer> cashierNumberColumn;

    // Simulation history table
    @FXML private TableView<Simulation> historyTable;

    @FXML private TableColumn<Simulation, Long> historyIdColumn;
    @FXML private TableColumn<Simulation, String> historyMethodColumn;
    @FXML private TableColumn<Simulation, Integer> historyCustomersColumn;
    @FXML private TableColumn<Simulation, Integer> historyCashiersColumn;
    @FXML private TableColumn<Simulation, Double> historyWaitColumn;
    @FXML private TableColumn<Simulation, String> historyDateColumn;

    // Chart
    @FXML private LineChart<Number, Number> waitingChart;

    // Result labels
    @FXML private Label averageWaitLabel;
    @FXML private Label averageServiceLabel;
    @FXML private Label totalTimeLabel;
    @FXML private Label statusLabel;

    // Services
    private final SimulationService simulationService =
            new SimulationService();

    private final SimulationRepository simulationRepository =
            new SimulationRepository();

    private static final DateTimeFormatter DATE_FORMAT =
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    // Initialize controller
    @FXML
    private void initialize() {

        // Available random generation methods
        methodCombo.setItems(FXCollections.observableArrayList(
                "Transformada inversa",
                "Convolución",
                "Composición"
        ));

        methodCombo.getSelectionModel().selectFirst();

        // Default simulation values
        customersField.setText("20");
        cashiersField.setText("2");

        configureCustomerTable();
        configureHistoryTable();

        waitingChart.setCreateSymbols(false);
        waitingChart.setAnimated(false);

        averageWaitLabel.setText("0.00 min");
        averageServiceLabel.setText("0.00 min");
        totalTimeLabel.setText("0.00 min");

        // Connect and create tables
        try {

            Database.initializeDatabase();

            loadHistory();

            statusLabel.setText(
                    "PostgreSQL conectado correctamente."
            );

        } catch (SQLException e) {

            statusLabel.setText(
                    "No se pudo conectar con PostgreSQL."
            );

            System.err.println(e.getMessage());
        }
    }

    // Configure customer columns
    private void configureCustomerTable() {

        customerNumberColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getCustomerNumber()));

        arrivalTimeColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getArrivalTime()));

        serviceTimeColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getServiceTime()));

        startTimeColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getStartTime()));

        waitTimeColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getWaitTime()));

        departureTimeColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getDepartureTime()));

        cashierNumberColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getCashierNumber()));

        formatDoubleColumn(arrivalTimeColumn);
        formatDoubleColumn(serviceTimeColumn);
        formatDoubleColumn(startTimeColumn);
        formatDoubleColumn(waitTimeColumn);
        formatDoubleColumn(departureTimeColumn);
    }

    // Configure history columns
    private void configureHistoryTable() {

        historyIdColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getId()));

        historyMethodColumn.setCellValueFactory(data ->
                new ReadOnlyStringWrapper(
                        data.getValue().getMethod()));

        historyCustomersColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getNumberOfCustomers()));

        historyCashiersColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getNumberOfCashiers()));

        historyWaitColumn.setCellValueFactory(data ->
                new ReadOnlyObjectWrapper<>(
                        data.getValue().getAverageWait()));

        historyDateColumn.setCellValueFactory(data -> {

            Simulation simulation = data.getValue();

            String date = simulation.getCreatedAt() == null
                    ? "-"
                    : simulation.getCreatedAt().format(DATE_FORMAT);

            return new ReadOnlyStringWrapper(date);
        });

        formatDoubleColumn(historyWaitColumn);
    }

    // Display decimal numbers with two digits
    private <T> void formatDoubleColumn(
            TableColumn<T, Double> column) {

        column.setCellFactory(col -> new TableCell<>() {

            @Override
            protected void updateItem(Double value, boolean empty) {

                super.updateItem(value, empty);

                if (empty || value == null) {
                    setText(null);
                } else {
                    setText(String.format(
                            Locale.US, "%.2f", value));
                }
            }
        });
    }

    // Start simulation button
    @FXML
    private void handleRunSimulation() {

        try {

            int numberOfCustomers = Integer.parseInt(
                    customersField.getText().trim());

            int numberOfCashiers = Integer.parseInt(
                    cashiersField.getText().trim());

            if (numberOfCustomers < 1 ||
                    numberOfCustomers > 1000) {

                showAlert(
                        Alert.AlertType.WARNING,
                        "Número de clientes",
                        "Introduce entre 1 y 1000 clientes."
                );

                return;
            }

            if (numberOfCashiers < 1 ||
                    numberOfCashiers > 50) {

                showAlert(
                        Alert.AlertType.WARNING,
                        "Número de cajeros",
                        "Introduce entre 1 y 50 cajeros."
                );

                return;
            }

            String method = methodCombo.getValue();

            if (method == null) {

                showAlert(
                        Alert.AlertType.WARNING,
                        "Método requerido",
                        "Selecciona un método de generación."
                );

                return;
            }

            // Generate random simulation
            SimulationService.SimulationResult result =
                    simulationService.generateSimulation(
                            method,
                            numberOfCustomers,
                            numberOfCashiers
                    );

            Simulation simulation = result.simulation();
            List<Customer> customers = result.customers();

            // Show results
            displayResults(simulation, customers);

            // Save results in PostgreSQL
            try {

                Database.initializeDatabase();

                simulationRepository.saveSimulation(
                        simulation,
                        customers
                );

                statusLabel.setText(
                        "Simulación guardada. ID: "
                                + simulation.getId()
                );

                try {
                    loadHistory();
                } catch (SQLException e) {
                    statusLabel.setText(
                            "Guardada, pero no se pudo actualizar el historial."
                    );
                }

            } catch (SQLException e) {

                statusLabel.setText(
                        "Simulación generada, pero no guardada."
                );

                showAlert(
                        Alert.AlertType.ERROR,
                        "Error de PostgreSQL",
                        "No se pudieron guardar los resultados:\n"
                                + e.getMessage()
                );
            }

        } catch (NumberFormatException e) {

            showAlert(
                    Alert.AlertType.WARNING,
                    "Datos incorrectos",
                    "Introduce números enteros válidos."
            );

        } catch (IllegalArgumentException e) {

            showAlert(
                    Alert.AlertType.ERROR,
                    "Error de simulación",
                    e.getMessage()
            );
        }
    }

    // Display simulation results
    private void displayResults(
            Simulation simulation,
            List<Customer> customers) {

        customerTable.setItems(
                FXCollections.observableArrayList(customers)
        );

        averageWaitLabel.setText(
                formatMinutes(simulation.getAverageWait())
        );

        averageServiceLabel.setText(
                formatMinutes(simulation.getAverageService())
        );

        totalTimeLabel.setText(
                formatMinutes(simulation.getTotalTime())
        );

        updateChart(customers);
    }

    // Update customer waiting and service chart
    private void updateChart(List<Customer> customers) {

        XYChart.Series<Number, Number> waitingSeries =
                new XYChart.Series<>();

        waitingSeries.setName("Tiempo de espera");

        XYChart.Series<Number, Number> serviceSeries =
                new XYChart.Series<>();

        serviceSeries.setName("Tiempo de atención");

        for (Customer customer : customers) {

            waitingSeries.getData().add(
                    new XYChart.Data<>(
                            customer.getCustomerNumber(),
                            customer.getWaitTime()
                    )
            );

            serviceSeries.getData().add(
                    new XYChart.Data<>(
                            customer.getCustomerNumber(),
                            customer.getServiceTime()
                    )
            );
        }

        waitingChart.getData().setAll(
                waitingSeries,
                serviceSeries
        );
    }

    // Refresh history button
    @FXML
    private void handleRefreshHistory() {

        try {

            loadHistory();

            statusLabel.setText(
                    "Historial actualizado correctamente."
            );

        } catch (SQLException e) {

            showAlert(
                    Alert.AlertType.ERROR,
                    "Error de PostgreSQL",
                    e.getMessage()
            );
        }
    }

    // Load saved simulations
    private void loadHistory() throws SQLException {

        List<Simulation> simulations =
                simulationRepository.getAllSimulations();

        historyTable.setItems(
                FXCollections.observableArrayList(simulations)
        );
    }

    // View selected simulation from history
    @FXML
    private void handleViewSimulation() {

        Simulation selected =
                historyTable.getSelectionModel().getSelectedItem();

        if (selected == null) {

            showAlert(
                    Alert.AlertType.INFORMATION,
                    "Seleccionar simulación",
                    "Selecciona una simulación del historial."
            );

            return;
        }

        try {

            List<Customer> customers =
                    simulationRepository.getCustomersBySimulationId(
                            selected.getId()
                    );

            displayResults(selected, customers);

            statusLabel.setText(
                    "Mostrando simulación ID: "
                            + selected.getId()
            );

        } catch (SQLException e) {

            showAlert(
                    Alert.AlertType.ERROR,
                    "Error al consultar",
                    e.getMessage()
            );
        }
    }

    // Format time in minutes
    private String formatMinutes(double value) {

        return String.format(
                Locale.US, "%.2f min", value
        );
    }

    // Display alert messages
    private void showAlert(
            Alert.AlertType type,
            String title,
            String message) {

        Alert alert = new Alert(type);

        alert.setTitle(title);
        alert.setHeaderText(null);
        alert.setContentText(message);

        alert.showAndWait();
    }
}
