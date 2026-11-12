//! A small RFC 4180 CSV reader.
//!
//! Handles the quirks real exports throw at us: a UTF-8 BOM, quoted fields,
//! escaped quotes (`""`), embedded commas and newlines, and both `\n` and
//! `\r\n` record separators. Cells are returned verbatim — no trimming — so a
//! password that legitimately starts or ends with a space survives the trip.
//!
//! The parser is pure and has no dependency on the vault model, which keeps it
//! easy to test in isolation.

use crate::error::Error;

/// Parse a CSV document into rows of cells.
///
/// Returns [`Error::Corrupted`] when the input ends inside a quoted field.
pub fn parse(input: &str) -> Result<Vec<Vec<String>>, Error> {
    // A leading BOM is an encoding artifact, never data.
    let input = input.strip_prefix('\u{feff}').unwrap_or(input);

    let mut rows: Vec<Vec<String>> = Vec::new();
    let mut row: Vec<String> = Vec::new();
    let mut field = String::new();
    let mut in_quotes = false;
    // Whether the current row has seen a delimiter or any content. Used to
    // flush the final row when the file does not end with a newline.
    let mut row_started = false;

    let mut chars = input.chars().peekable();
    while let Some(ch) = chars.next() {
        if in_quotes {
            match ch {
                '"' => {
                    if chars.peek() == Some(&'"') {
                        chars.next();
                        field.push('"');
                    } else {
                        in_quotes = false;
                    }
                }
                other => field.push(other),
            }
            continue;
        }

        match ch {
            '"' if field.is_empty() => {
                in_quotes = true;
                row_started = true;
            }
            // A quote in the middle of an unquoted field is kept literally.
            '"' => field.push('"'),
            ',' => {
                row.push(std::mem::take(&mut field));
                row_started = true;
            }
            '\r' => {
                if chars.peek() == Some(&'\n') {
                    chars.next();
                }
                row.push(std::mem::take(&mut field));
                rows.push(std::mem::take(&mut row));
                row_started = false;
            }
            '\n' => {
                row.push(std::mem::take(&mut field));
                rows.push(std::mem::take(&mut row));
                row_started = false;
            }
            other => {
                field.push(other);
                row_started = true;
            }
        }
    }

    if in_quotes {
        return Err(Error::Corrupted);
    }
    if row_started || !field.is_empty() {
        row.push(field);
        rows.push(row);
    }
    Ok(rows)
}

/// Escape one field for CSV output.
///
/// A field is quoted only when it contains a comma, a double quote or a line
/// break; embedded quotes are doubled.
pub fn escape(field: &str) -> String {
    if !field.chars().any(|c| matches!(c, ',' | '"' | '\n' | '\r')) {
        return field.to_string();
    }
    let mut out = String::with_capacity(field.len() + 2);
    out.push('"');
    for ch in field.chars() {
        if ch == '"' {
            out.push('"');
        }
        out.push(ch);
    }
    out.push('"');
    out
}

/// Join one row of fields into a CSV record (without a trailing newline).
pub fn write_row(fields: &[&str]) -> String {
    fields
        .iter()
        .map(|field| escape(field))
        .collect::<Vec<_>>()
        .join(",")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_simple_rows() {
        let rows = parse("a,b,c\nd,e,f\n").unwrap();
        assert_eq!(rows, vec![vec!["a", "b", "c"], vec!["d", "e", "f"]]);
    }

    #[test]
    fn strips_a_utf8_bom() {
        let rows = parse("\u{feff}name,url\nAda,https://example.com").unwrap();
        assert_eq!(rows[0], vec!["name", "url"]);
    }

    #[test]
    fn handles_quotes_commas_and_escaped_quotes() {
        let rows = parse("a,\"b,c\",\"d\"\"e\"\n").unwrap();
        assert_eq!(rows, vec![vec!["a", "b,c", "d\"e"]]);
    }

    #[test]
    fn handles_newlines_inside_quotes() {
        let rows = parse("a,\"line1\nline2\",b\n").unwrap();
        assert_eq!(rows, vec![vec!["a", "line1\nline2", "b"]]);
    }

    #[test]
    fn handles_crlf_and_no_trailing_newline() {
        let rows = parse("a,b\r\nc,d").unwrap();
        assert_eq!(rows, vec![vec!["a", "b"], vec!["c", "d"]]);
    }

    #[test]
    fn keeps_empty_fields() {
        let rows = parse("a,,c\n").unwrap();
        assert_eq!(rows, vec![vec!["a", "", "c"]]);
    }

    #[test]
    fn preserves_significant_spaces() {
        let rows = parse("\"  secret  \",x\n").unwrap();
        assert_eq!(rows[0][0], "  secret  ");
    }

    #[test]
    fn empty_input_yields_no_rows() {
        assert!(parse("").unwrap().is_empty());
    }

    #[test]
    fn unterminated_quote_is_an_error() {
        assert_eq!(parse("a,\"unterminated").unwrap_err(), Error::Corrupted);
    }

    #[test]
    fn escapes_only_when_needed() {
        assert_eq!(escape("plain"), "plain");
        assert_eq!(escape("a,b"), "\"a,b\"");
        assert_eq!(escape("a\"b"), "\"a\"\"b\"");
        assert_eq!(escape("line\nbreak"), "\"line\nbreak\"");
    }

    #[test]
    fn written_rows_round_trip_through_the_parser() {
        let row = ["My, Site", "https://x.example", "ada", "p\"w", "note\nhere"];
        let line = format!("{}\n", write_row(&row));
        let parsed = parse(&line).unwrap();
        assert_eq!(parsed, vec![row.map(String::from).to_vec()]);
    }
}
