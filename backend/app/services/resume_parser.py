import os
import re
from typing import Dict, Any, List, Optional
from pypdf import PdfReader
import docx


class ResumeParser:
    """Extracts raw text and parsed structured sections from PDF, DOCX, and TXT files."""

    @staticmethod
    def extract_text_from_file(file_path: str, file_type: str) -> str:
        """Extract all readable text from the uploaded resume file."""
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Resume file not found at: {file_path}")

        file_type = file_type.lower().strip().replace(".", "")

        if file_type == "pdf":
            return ResumeParser._extract_from_pdf(file_path)
        elif file_type in ["docx", "doc"]:
            return ResumeParser._extract_from_docx(file_path)
        elif file_type == "txt":
            return ResumeParser._extract_from_txt(file_path)
        else:
            # Attempt general text read
            try:
                return ResumeParser._extract_from_txt(file_path)
            except Exception:
                raise ValueError(f"Unsupported resume file type: {file_type}")

    @staticmethod
    def _extract_from_pdf(file_path: str) -> str:
        text_chunks = []
        try:
            reader = PdfReader(file_path)
            for page_idx, page in enumerate(reader.pages):
                page_text = page.extract_text()
                if page_text:
                    text_chunks.append(page_text.strip())
            
            full_text = "\n\n".join(text_chunks).strip()
            if not full_text:
                return "Uploaded PDF file contains no extractable text or is image-based."
            return full_text
        except Exception as e:
            # Fallback handling
            return f"Error extracting text from PDF: {str(e)}"

    @staticmethod
    def _extract_from_docx(file_path: str) -> str:
        try:
            doc = docx.Document(file_path)
            full_text = []
            for para in doc.paragraphs:
                if para.text.strip():
                    full_text.append(para.text.strip())
            
            # Also extract text from tables
            for table in doc.tables:
                for row in table.rows:
                    row_text = [cell.text.strip() for cell in row.cells if cell.text.strip()]
                    if row_text:
                        full_text.append(" | ".join(row_text))
            
            extracted = "\n".join(full_text).strip()
            if not extracted:
                return "Uploaded document is empty."
            return extracted
        except Exception as e:
            return f"Error extracting text from DOCX: {str(e)}"

    @staticmethod
    def _extract_from_txt(file_path: str) -> str:
        encodings = ["utf-8", "latin-1", "windows-1252", "ascii"]
        for enc in encodings:
            try:
                with open(file_path, "r", encoding=enc) as f:
                    return f.read().strip()
            except UnicodeDecodeError:
                continue
        with open(file_path, "rb") as f:
            return f.read().decode("utf-8", errors="replace").strip()

    @staticmethod
    def extract_contact_info(text: str) -> Dict[str, Any]:
        """Extract email, phone, links, and potential name from raw text."""
        info = {
            "name": None,
            "email": None,
            "phone": None,
            "location": None,
            "linkedin": None,
            "github": None,
            "portfolio": None,
        }

        # Email
        email_pattern = r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'
        email_match = re.search(email_pattern, text)
        if email_match:
            info["email"] = email_match.group(0).strip()

        # Phone
        phone_pattern = r'(\+?\d{1,3}[-.\s]?)?(\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}'
        phone_match = re.search(phone_pattern, text)
        if phone_match:
            info["phone"] = phone_match.group(0).strip()

        # LinkedIn
        linkedin_pattern = r'(https?://)?(www\.)?linkedin\.com/in/[a-zA-Z0-9_-]+/?'
        linkedin_match = re.search(linkedin_pattern, text, re.IGNORECASE)
        if linkedin_match:
            info["linkedin"] = linkedin_match.group(0).strip()

        # GitHub
        github_pattern = r'(https?://)?(www\.)?github\.com/[a-zA-Z0-9_-]+/?'
        github_match = re.search(github_pattern, text, re.IGNORECASE)
        if github_match:
            info["github"] = github_match.group(0).strip()

        # Portfolio / Website
        portfolio_pattern = r'(https?://)?(www\.)?[a-zA-Z0-9-]+\.(me|io|dev|app|site|tech|com)(/[a-zA-Z0-9_-]+)?'
        portfolio_match = re.search(portfolio_pattern, text, re.IGNORECASE)
        if portfolio_match and "github.com" not in portfolio_match.group(0) and "linkedin.com" not in portfolio_match.group(0):
            info["portfolio"] = portfolio_match.group(0).strip()

        # Name heuristic (first non-empty line without special keywords)
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        for line in lines[:5]:
            if len(line.split()) in [2, 3, 4] and not re.search(r'resume|cv|curriculum|developer|engineer|email|phone|http', line, re.I):
                info["name"] = line
                break

        return info


resume_parser = ResumeParser()
