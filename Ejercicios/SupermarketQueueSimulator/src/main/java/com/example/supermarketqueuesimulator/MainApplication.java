
package com.example.supermarketqueuesimulator;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.IOException;

public class MainApplication extends Application {

    @Override
    public void start(Stage stage) throws IOException {

        // Load supermarket interface
        FXMLLoader loader = new FXMLLoader(
                MainApplication.class.getResource(
                        "/com/example/supermarketqueuesimulator/simulator-view.fxml"
                )
        );

        Parent root = loader.load();

        // Create main window
        Scene scene = new Scene(root, 1150, 750);

        // Configure window
        stage.setTitle("Supermarket Queue Simulator");

        stage.setScene(scene);

        stage.setMinWidth(1000);
        stage.setMinHeight(650);

        stage.setResizable(true);

        // Display window
        stage.show();

        System.out.println(
                "Supermarket Queue Simulator started successfully!"
        );
    }

    public static void main(String[] args) {
        launch(args);
    }
}
