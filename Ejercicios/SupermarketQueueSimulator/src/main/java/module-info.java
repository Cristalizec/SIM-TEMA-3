
module com.example.supermarketqueuesimulator {

    requires javafx.controls;
    requires javafx.fxml;

    requires java.sql;
    requires org.postgresql.jdbc;

    opens com.example.supermarketqueuesimulator
            to javafx.fxml;

    exports com.example.supermarketqueuesimulator;
    exports com.example.supermarketqueuesimulator.controller;
    opens com.example.supermarketqueuesimulator.controller to javafx.fxml;
}
