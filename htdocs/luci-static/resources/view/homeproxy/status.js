/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2022-2025 ImmortalWrt.org
 */

'use strict';
'require dom';
'require form';
'require fs';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';

/* Thanks to luci-app-aria2 */
const css = '				\
.description {				\
	background-color: #33ccff;	\
}					\
.homeproxy-log-panel {			\
	border: 1px solid #d8dee6;	\
	border-radius: 4px;		\
	overflow: hidden;		\
	background: #fff;		\
}					\
.homeproxy-log-toolbar {		\
	display: flex;			\
	align-items: center;		\
	gap: 8px;			\
	padding: 10px;			\
	background: #f5f7fa;		\
	border-bottom: 1px solid #e4e8ef;	\
}					\
.homeproxy-log-tabs {			\
	display: grid;			\
	grid-template-columns: repeat(3, minmax(0, 1fr));	\
	gap: 10px;			\
	flex: 1;			\
}					\
.homeproxy-log-tab {			\
	border: 1px solid #d8dee6;	\
	border-radius: 4px;		\
	background: #fff;		\
	color: #333;			\
	padding: 8px 12px;		\
	text-align: center;		\
	cursor: pointer;		\
}					\
.homeproxy-log-tab.active {		\
	border-color: #3b82f6;		\
	background: #3b82f6;		\
	color: #fff;			\
	font-weight: 600;		\
}					\
.homeproxy-log-actions {		\
	display: flex;			\
	align-items: center;		\
	gap: 6px;			\
}					\
.homeproxy-log-table {			\
	max-height: 520px;		\
	overflow: auto;			\
	font-family: Consolas, Monaco, monospace;	\
	font-size: 13px;		\
	line-height: 1.5;		\
	text-align: left;		\
}					\
.homeproxy-log-row {			\
	display: grid;			\
	grid-template-columns: 42px 152px 96px minmax(360px, 1fr);	\
	align-items: center;		\
	min-width: 760px;		\
	border-bottom: 1px solid #f1f3f6;	\
}					\
.homeproxy-log-row:nth-child(odd) {	\
	background: #fcfdff;		\
}					\
.homeproxy-log-row:hover {		\
	background: #fff8df;		\
}					\
.homeproxy-log-cell {			\
	padding: 3px 6px;		\
	white-space: pre-wrap;		\
	word-break: break-word;		\
}					\
.homeproxy-log-line {			\
	color: #7f8794;			\
	text-align: right;		\
	background: #f6f8fb;		\
}					\
.homeproxy-log-time {			\
	color: #a855f7;			\
}					\
.homeproxy-log-level {			\
	display: inline-block;		\
	min-width: 68px;		\
	border-radius: 4px;		\
	padding: 1px 8px;		\
	text-align: center;		\
	font-weight: 600;		\
}					\
.homeproxy-log-level-info, .homeproxy-log-level-daemon {	\
	background: #d9f3f4;		\
	color: #0891b2;			\
}					\
.homeproxy-log-level-warn, .homeproxy-log-level-warning {	\
	background: #fde8d8;		\
	color: #f97316;			\
}					\
.homeproxy-log-level-error, .homeproxy-log-level-fatal, .homeproxy-log-level-panic {	\
	background: #ffd6d6;		\
	color: #ef4444;			\
}					\
.homeproxy-log-level-debug, .homeproxy-log-level-trace {	\
	background: #e5e7eb;		\
	color: #64748b;			\
}					\
.homeproxy-log-message.error, .homeproxy-log-message.fatal, .homeproxy-log-message.panic {	\
	color: #dc2626;			\
	font-weight: 600;		\
}					\
.homeproxy-log-message.warn, .homeproxy-log-message.warning {	\
	color: #c2410c;			\
	font-weight: 600;		\
}					\
.homeproxy-log-message.info, .homeproxy-log-message.daemon {	\
	color: #047857;			\
}';

const hp_dir = '/var/run/homeproxy';

function getConnStat(o, site) {
	const callConnStat = rpc.declare({
		object: 'luci.homeproxy',
		method: 'connection_check',
		params: ['site'],
		expect: { '': {} }
	});

	o.default = E('div', { 'style': 'cbi-value-field' }, [
		E('button', {
			'class': 'btn cbi-button cbi-button-action',
			'click': ui.createHandlerFn(this, () => {
				return L.resolveDefault(callConnStat(site), {}).then((ret) => {
                                        let ele = o.default.firstElementChild.nextElementSibling;
					if (ret.result) {
						ele.style.setProperty('color', 'green');
                                                ele.innerHTML = _('passed');
					} else {
						ele.style.setProperty('color', 'red');
                                                ele.innerHTML = _('failed');
					}
				});
			})
		}, [ _('Check') ]),
		' ',
		E('strong', { 'style': 'color:gray' }, _('unchecked')),
	]);
}

function getResVersion(o, type) {
	const callResVersion = rpc.declare({
		object: 'luci.homeproxy',
		method: 'resources_get_version',
		params: ['type'],
		expect: { '': {} }
	});

	const callResUpdate = rpc.declare({
		object: 'luci.homeproxy',
		method: 'resources_update',
		params: ['type'],
		expect: { '': {} }
	});

	return L.resolveDefault(callResVersion(type), {}).then((res) => {
		let spanTemp = E('div', { 'style': 'cbi-value-field' }, [
			E('button', {
				'class': 'btn cbi-button cbi-button-action',
				'click': ui.createHandlerFn(this, () => {
					return L.resolveDefault(callResUpdate(type), {}).then((res) => {
						switch (res.status) {
						case 0:
							o.description = _('Successfully updated.');
							break;
						case 1:
							o.description = _('Update failed.');
							break;
						case 2:
							o.description = _('Already in updating.');
							break;
						case 3:
							o.description = _('Already at the latest version.');
							break;
						default:
							o.description = _('Unknown error.');
							break;
						}

						return o.map.reset();
					});
				})
			}, [ _('Check update') ]),
			' ',
			E('strong', { 'style': (res.error ? 'color:red' : 'color:green') },
				[ res.error ? 'not found' : res.version ]
			),
		]);

		o.default = spanTemp;
	});
}

function parseLogLine(line) {
	let parsed = {
		time: '',
		level: '',
		message: line
	};

	let daemon = line.match(/^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+\[([^\]]+)\]\s*(.*)$/);
	if (daemon) {
		parsed.time = daemon[1];
		parsed.level = daemon[2];
		parsed.message = daemon[3];
		return parsed;
	}

	let singbox = line.match(/^([A-Z]+)(?:\[[^\]]*\])?\s+(.*)$/);
	if (singbox) {
		parsed.level = singbox[1];
		parsed.message = singbox[2];
	}

	return parsed;
}

function renderLogRows(content) {
	let lines = (content || '').trim().split(/\r?\n/).filter((line) => line.length);
	if (!lines.length)
		return E('div', { 'class': 'homeproxy-log-row' }, [
			E('span', { 'class': 'homeproxy-log-cell homeproxy-log-line' }, '1'),
			E('span', { 'class': 'homeproxy-log-cell homeproxy-log-time' }, ''),
			E('span', { 'class': 'homeproxy-log-cell' }, ''),
			E('span', { 'class': 'homeproxy-log-cell homeproxy-log-message' }, _('Log is empty.'))
		]);

	return lines.map((line, idx) => {
		let item = parseLogLine(line);
		let level = (item.level || '').toLowerCase();

		return E('div', { 'class': 'homeproxy-log-row' }, [
			E('span', { 'class': 'homeproxy-log-cell homeproxy-log-line' }, String(idx + 1)),
			E('span', { 'class': 'homeproxy-log-cell homeproxy-log-time' }, item.time),
			E('span', { 'class': 'homeproxy-log-cell' }, item.level ?
				E('span', { 'class': 'homeproxy-log-level homeproxy-log-level-' + level }, item.level) : ''),
			E('span', { 'class': 'homeproxy-log-cell homeproxy-log-message ' + level }, item.message)
		]);
	});
}

function createLogLevelSelect(map, section) {
	if (!section)
		return '';

	const selected = uci.get('homeproxy', section, 'log_level') || 'warn';
	const choices = {
		trace: _('Trace'),
		debug: _('Debug'),
		info: _('Info'),
		warn: _('Warn'),
		error: _('Error'),
		fatal: _('Fatal'),
		panic: _('Panic')
	};

	let log_level_el = E('select', {
		'class': 'cbi-input-select',
		'style': 'width: 6em;',
		'change': ui.createHandlerFn(this, (ev) => {
			uci.set('homeproxy', section, 'log_level', ev.target.value);
			return map.save(null, true).then(() => {
				ui.changes.apply(true);
			});
		})
	});

	Object.keys(choices).forEach((v) => {
		log_level_el.appendChild(E('option', {
			'value': v,
			'selected': (v === selected) ? '' : null
		}, [ choices[v] ]));
	});

	return log_level_el;
}

function getLogSection(filename) {
	let section;
	switch (filename) {
	case 'homeproxy':
		section = null;
		break;
	case 'sing-box-c':
		section = 'config';
		break;
	case 'sing-box-s':
		section = 'server';
		break;
	}

	return section;
}

function renderLogPanel(map) {
	const callLogClean = rpc.declare({
		object: 'luci.homeproxy',
		method: 'log_clean',
		params: ['type'],
		expect: { '': {} }
	});

	let activeLog = 'homeproxy';
	const logs = [
		{ file: 'homeproxy', title: _('HomeProxy log') },
		{ file: 'sing-box-c', title: _('sing-box client log') },
		{ file: 'sing-box-s', title: _('sing-box server log') }
	];
	const tabNodes = {};
	const logTable = E('div', { 'class': 'homeproxy-log-table' },
		E('img', {
			'src': L.resource('icons/loading.svg'),
			'alt': _('Loading'),
			'style': 'vertical-align:middle'
		}, _('Collecting data...'))
	);
	const actions = E('div', { 'class': 'homeproxy-log-actions' });

	function refreshLog() {
		return fs.read_direct(String.format('%s/%s.log', hp_dir, activeLog), 'text')
		.then((res) => {
			dom.content(logTable, renderLogRows(res));
		}).catch((err) => {
			let msg;
			if (err.toString().includes('NotFoundError'))
				msg = _('Log file does not exist.');
			else
				msg = _('Unknown error: %s').format(err);

			dom.content(logTable, renderLogRows(msg));
		});
	}

	function renderActions() {
		dom.content(actions, [
			createLogLevelSelect(map, getLogSection(activeLog)),
			E('button', {
				'class': 'btn cbi-button cbi-button-action',
				'click': ui.createHandlerFn(this, () => {
					return L.resolveDefault(callLogClean(activeLog), {});
				})
			}, [ _('Clean log') ])
		]);
	}

	function setActiveLog(filename) {
		activeLog = filename;
		for (let file in tabNodes)
			tabNodes[file].classList.toggle('active', file === activeLog);
		renderActions();
		refreshLog();
	}

	poll.add(L.bind(() => {
		return refreshLog();
	}));

	let tabs = E('div', { 'class': 'homeproxy-log-tabs' }, logs.map((log) => {
		let tab = E('button', {
			'class': 'homeproxy-log-tab',
			'click': ui.createHandlerFn(this, () => {
				setActiveLog(log.file);
			})
		}, [ log.title ]);
		tabNodes[log.file] = tab;
		return tab;
	}));

	renderActions();
	setActiveLog(activeLog);

	return E([
		E('style', [ css ]),
		E('div', { 'class': 'cbi-map' }, [
			E('div', { 'class': 'homeproxy-log-panel' }, [
				E('div', { 'class': 'homeproxy-log-toolbar' }, [
					tabs,
					actions
				]),
				logTable,
				E('div', { 'style': 'text-align:right; padding: 6px 10px; background: #f8fafc;' },
					E('small', {}, _('Refresh every %s seconds.').format(L.env.pollinterval))
				)
			])
		])
	]);
}

return view.extend({
	render() {
		let m, s, o;

		m = new form.Map('homeproxy');

		s = m.section(form.NamedSection, 'config', 'homeproxy', _('Connection check'));
		s.anonymous = true;

		o = s.option(form.DummyValue, '_check_baidu', _('BaiDu'));
		o.cfgvalue = L.bind(getConnStat, this, o, 'baidu');

		o = s.option(form.DummyValue, '_check_google', _('Google'));
		o.cfgvalue = L.bind(getConnStat, this, o, 'google');

		s = m.section(form.NamedSection, 'config', 'homeproxy', _('Resources management'));
		s.anonymous = true;

		o = s.option(form.DummyValue, '_china_ip4_version', _('China IPv4 list version'));
		o.cfgvalue = L.bind(getResVersion, this, o, 'china_ip4');
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_china_ip6_version', _('China IPv6 list version'));
		o.cfgvalue = L.bind(getResVersion, this, o, 'china_ip6');
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_china_list_version', _('China list version'));
		o.cfgvalue = L.bind(getResVersion, this, o, 'china_list');
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_gfw_list_version', _('GFW list version'));
		o.cfgvalue = L.bind(getResVersion, this, o, 'gfw_list');
		o.rawhtml = true;

		o = s.option(form.Value, 'github_token', _('GitHub token'));
		o.password = true;
		o.renderWidget = function() {
			let node = form.Value.prototype.renderWidget.apply(this, arguments);

			(node.querySelector('.control-group') || node).appendChild(E('button', {
				'class': 'cbi-button cbi-button-apply',
				'title': _('Save'),
				'click': ui.createHandlerFn(this, () => {
					return this.map.save(null, true).then(() => {
						ui.changes.apply(true);
					});
				}, this.option)
			}, [ _('Save') ]));

			return node;
		}

		s = m.section(form.NamedSection, 'config', 'homeproxy');
		s.anonymous = true;

		o = s.option(form.DummyValue, '_runtime_logview');
		o.render = L.bind(renderLogPanel, this, m);

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
