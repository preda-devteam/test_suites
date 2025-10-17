use tracing::info;
extern crate csv;
use std::fs::File;
use csv::{ReaderBuilder, StringRecord};

pub fn get_records_from_file(path: String) -> Vec<StringRecord> {
    // Open the file in read-only mode
    let file_result = File::open(path);
    let mut records: Vec<StringRecord> = Vec::new();

    // Match on the result of opening the file
    match file_result {
        Ok(file) => {
            // Create a CSV Reader with flexible settings
            let mut csv_reader = ReaderBuilder::new()
                .delimiter(b',')
                .from_reader(file);

            // Iterate over each record in the CSV file
            for record_result in csv_reader.records() {
                // Match on the result of reading each record
                match record_result {
                    Ok(record) => {
                        // Process the record
                        records.push(record);
                    },
                    Err(err) => {
                        // Handle the error if reading the record fails
                        info!("Error reading CSV record: {}", err);
                    }
                }
            }
        },
        Err(err) => {
            // Handle the error if opening the file fails
            info!("Error opening CSV file: {}", err);
        }
    }
    records
}