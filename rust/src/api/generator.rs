//! Password generation exposed to Dart.

use keyel_core::generator::{
    generate_passphrase as core_generate_passphrase, generate_password as core_generate,
    GenerateError, PassphraseOptions, PasswordOptions,
};

/// Generate a random password.
#[flutter_rust_bridge::frb(sync)]
pub fn generate_password(
    length: i32,
    lowercase: bool,
    uppercase: bool,
    digits: bool,
    symbols: bool,
    exclude_ambiguous: bool,
) -> Result<String, GeneratorApiError> {
    let options = PasswordOptions {
        length: length.clamp(4, 128) as usize,
        lower: lowercase,
        upper: uppercase,
        digits,
        symbols,
        exclude_ambiguous,
        ..PasswordOptions::default()
    };
    core_generate(&options)
        .map_err(GeneratorApiError::from)
        .map(|p| p.as_str().to_owned())
}

/// Generate a secure, memorable passphrase.
#[flutter_rust_bridge::frb(sync)]
pub fn generate_passphrase(
    word_count: i32,
    capitalize: bool,
    include_number: bool,
    separator: String,
) -> Result<String, GeneratorApiError> {
    let options = PassphraseOptions {
        word_count: word_count.clamp(3, 12) as usize,
        capitalize,
        include_number,
        separator,
    };
    core_generate_passphrase(&options)
        .map_err(GeneratorApiError::from)
        .map(|p| p.as_str().to_owned())
}

/// Error surface for the generator API.
#[derive(Debug)]
pub enum GeneratorApiError {
    ImpossibleConstraints,
    NoCharClass,
    InvalidOptions,
}

impl From<GenerateError> for GeneratorApiError {
    fn from(e: GenerateError) -> Self {
        match e {
            GenerateError::ImpossibleConstraints { .. } => Self::ImpossibleConstraints,
            GenerateError::NoCharClass => Self::NoCharClass,
            GenerateError::InvalidPassphraseOptions => Self::InvalidOptions,
        }
    }
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
