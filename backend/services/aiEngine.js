/**
 * AI Engine - Rule-based NLP for Intent Detection
 * Detects module, type, section, date, and intent from natural language queries
 */

const db = require('../config/db');

class AIEngine {
	constructor() {
		// Keywords for module detection
		this.moduleKeywords = {
			masjid: ['masjid', 'mosque', 'مسجد'],
			madrasa: ['madrasa', 'madrasah', 'مدرسہ', 'مدرسے']
		};

		// Keywords for type detection
		this.typeKeywords = {
			income: ['income', 'revenue', 'earning', 'آمدنی', 'آمدن', 'وصولی'],
			expenditure: ['expenditure', 'expense', 'spending', 'cost', 'خرچ', 'اخراجات', 'خرچہ']
		};

		// Keywords for intent detection
		this.intentKeywords = {
			total: ['total', 'sum', 'کل', 'مجموعی'],
			net_balance: ['net', 'balance', 'profit', 'loss', 'خالص', 'بیلنس'],
			compare: ['compare', 'comparison', 'vs', 'versus', 'موازنہ', 'تقابل'],
			summary: ['summary', 'report', 'overview', 'خلاصہ', 'رپورٹ'],
			breakdown: ['breakdown', 'section', 'wise', 'تفصیل', 'سیکشن']
		};

		// Month names mapping
		this.monthNames = {
			'january': 1, 'jan': 1, 'جنوری': 1,
			'february': 2, 'feb': 2, 'فروری': 2,
			'march': 3, 'mar': 3, 'مارچ': 3,
			'april': 4, 'apr': 4, 'اپریل': 4,
			'may': 5, 'مئی': 5,
			'june': 6, 'jun': 6, 'جون': 6,
			'july': 7, 'jul': 7, 'جولائی': 7,
			'august': 8, 'aug': 8, 'اگست': 8,
			'september': 9, 'sep': 9, 'ستمبر': 9,
			'october': 10, 'oct': 10, 'اکتوبر': 10,
			'november': 11, 'nov': 11, 'نومبر': 11,
			'december': 12, 'dec': 12, 'دسمبر': 12
		};
	}

	_escapeRegex(s) {
		return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	}

	async parse(message) {
		const lowerMessage = message.toLowerCase();

		const intent = {
			module: this.detectModule(lowerMessage),
			type: this.detectType(lowerMessage),
			section: await this.detectSection(lowerMessage),
			year: this.detectYear(lowerMessage),
			month: this.detectMonth(lowerMessage),
			intent: this.detectIntent(lowerMessage),
			originalMessage: message
		};

		return intent;
	}

	detectModule(message) {
		for (const [mod, keywords] of Object.entries(this.moduleKeywords)) {
			for (const keyword of keywords) {
				const rx = new RegExp('\\b' + this._escapeRegex(keyword) + '\\b', 'i');
				if (rx.test(message)) return mod;
			}
		}
		return 'masjid';
	}

	detectType(message) {
		for (const k of this.typeKeywords.expenditure) {
			const rx = new RegExp('\\b' + this._escapeRegex(k) + '\\b', 'i');
			if (rx.test(message)) return 'expenditure';
		}
		for (const k of this.typeKeywords.income) {
			const rx = new RegExp('\\b' + this._escapeRegex(k) + '\\b', 'i');
			if (rx.test(message)) return 'income';
		}
		if (/\b(net|balance|summary|خالص|خلاصہ)\b/i.test(message)) return 'both';
		return 'income';
	}

	async detectSection(message) {
		try {
			const query = `SELECT DISTINCT name FROM sections ORDER BY name`;
			const result = await db.query(query, []);
			if (result.rows.length === 0) return null;

			const sections = result.rows.map(r => ({ original: r.name, lower: r.name.toLowerCase() }));

			for (const section of sections) {
				const rx = new RegExp('\\b' + this._escapeRegex(section.lower) + '\\b', 'i');
				if (rx.test(message)) return section.lower;
			}

			const messageWords = message.split(/\s+/).map(w => w.replace(/[^\w\u0600-\u06FF]/g, ''));
			for (const section of sections) {
				for (const word of messageWords) {
					if (!word) continue;
					if (word === section.lower || section.lower.includes(word)) return section.lower;
				}
			}
			return null;
		} catch (err) {
			console.error('❌ Error detecting section:', err);
			return null;
		}
	}

	detectYear(message) {
		const yearMatch = message.match(/\b(20\d{2})\b/);
		if (yearMatch) return parseInt(yearMatch[1]);
		const currentYear = new Date().getFullYear();
		if (/\blast year\b|\bپچھلے سال\b|\bگزشتہ سال\b/i.test(message)) return currentYear - 1;
		if (/\bthis year\b|\bاس سال\b|\bموجودہ سال\b/i.test(message)) return currentYear;
		return null;
	}

	detectMonth(message) {
		for (const [name, num] of Object.entries(this.monthNames)) {
			const rx = new RegExp('\\b' + this._escapeRegex(name) + '\\b', 'i');
			if (rx.test(message)) return num;
		}
		if (/\blast month\b|\bپچھلے مہینے\b/i.test(message)) {
			const lastMonth = new Date().getMonth();
			return lastMonth === 0 ? 12 : lastMonth;
		}
		return null;
	}

	detectIntent(message) {
		for (const k of this.intentKeywords.compare) {
			const rx = new RegExp('\\b' + this._escapeRegex(k) + '\\b', 'i');
			if (rx.test(message)) return 'compare';
		}
		for (const k of this.intentKeywords.net_balance) {
			const rx = new RegExp('\\b' + this._escapeRegex(k) + '\\b', 'i');
			if (rx.test(message)) return 'net_balance';
		}
		for (const k of this.intentKeywords.summary) {
			const rx = new RegExp('\\b' + this._escapeRegex(k) + '\\b', 'i');
			if (rx.test(message)) return 'summary';
		}
		for (const k of this.intentKeywords.breakdown) {
			const rx = new RegExp('\\b' + this._escapeRegex(k) + '\\b', 'i');
			if (rx.test(message)) return 'breakdown';
		}
		for (const k of this.intentKeywords.total) {
			const rx = new RegExp('\\b' + this._escapeRegex(k) + '\\b', 'i');
			if (rx.test(message)) return 'total';
		}
		return 'total';
	}
}

module.exports = new AIEngine();


