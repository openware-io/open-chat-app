const app = document.querySelector('#app');
const toast = document.querySelector('#toast');
const data = window.A380_DATA;

const state = {
  cart: readLocal('a380-cart', {}),
  orders: readLocal('a380-orders', []),
  venueSort: {},
  ktvRooms: [
    ['K01 小包', '空闲', '绿色'], ['K02 小包', '占用', '蓝色'], ['K03 小包', '预定', '橙色'],
    ['K06 中包', '占用', '蓝色'], ['K08 中包', '清理中', '紫色'], ['K09 中包', '空闲', '绿色'],
    ['K12 大包', '占用', '蓝色'], ['K15 大包', '维护', '灰色'], ['VIP 01', '预定', '橙色'],
  ],
  travel: {
    from: '深圳', to: '重庆',
    fromDetail: '深圳宝安国际机场 T3', toDetail: '重庆江北国际机场 T3',
    date: dateOffset(1), people: '1成人',
    pickup: '深圳宝安国际机场 T3', dropoff: '深圳湾科技生态园',
  },
};

function readLocal(key, fallback) {
  try { return JSON.parse(localStorage.getItem(key)) ?? fallback; } catch (_) { return fallback; }
}
function saveLocal(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch (_) { /* WebView private mode fallback */ }
}
function dateOffset(days) {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString().slice(0, 10);
}
function formatDate(value) {
  const date = new Date(`${value}T00:00:00`);
  return `${date.getMonth() + 1}月${date.getDate()}日`;
}
function money(value) { return `¥${Number(value).toLocaleString('zh-CN')}`; }
function image(name) { return `./assets/images/${name}`; }
function escapeHtml(value = '') {
  return String(value).replace(/[&<>'"]/g, char => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', "'":'&#39;', '"':'&quot;' })[char]);
}
function orderNo() { return `A380${Date.now().toString().slice(-10)}`; }
function go(route) { location.hash = `#/${route}`; }
function showToast(message) {
  toast.textContent = message;
  toast.classList.add('show');
  clearTimeout(showToast.timer);
  showToast.timer = setTimeout(() => toast.classList.remove('show'), 1800);
}
function pageHead(title, right = '<button class="head-action" data-route="orders">订单</button>') {
  return `<header class="page-head"><button class="icon-button" data-back aria-label="返回">‹</button><h1>${title}</h1>${right}</header>`;
}
function emptyState(icon, title, copy) {
  return `<section class="empty"><span>${icon}</span><h2>${title}</h2><p>${copy}</p></section>`;
}
function serviceById(id) { return data.services.find(item => item.id === id); }
function addOrder(order) {
  state.orders.unshift(order);
  saveLocal('a380-orders', state.orders);
}

function renderHome() {
  app.innerHTML = `
    <section class="wallet">
      <h1 class="brand">A380</h1>
      <div class="balances">
        <button class="balance" data-route="ledger/coin"><span class="balance-label">A380币：</span><strong>8,880</strong></button>
        <button class="balance" data-route="ledger/points"><span class="balance-label">积分：</span><strong>12,680</strong></button>
      </div>
      <nav class="service-grid" aria-label="更多服务">
        ${data.services.map(item => `<button class="service-button" data-route="service/${item.id}"><span class="service-icon">${item.icon}</span><span class="service-name">${item.name}</span></button>`).join('')}
      </nav>
    </section>
    <div class="section-head"><h2>热门服务</h2><button data-toast="更多服务持续更新中">查看全部 ›</button></div>
    <section class="mini-grid">
      ${[
        ['hotel', 'A380酒店', 'hotel-1.jpg', '豪华房低至 ¥368'],
        ['bar', 'A380酒吧', 'bar-1.jpg', '散台 / 卡座在线预订'],
        ['billiards', 'A380台球厅', 'billiards-1.png', '专业球台 · 到店即玩'],
        ['foot', 'A380足浴', 'foot-1.png', '放松身心 · 预约免排队'],
      ].map(([id, title, pic, note]) => `<button class="mini-card" data-route="service/${id}"><img src="${image(pic)}" alt="${title}"><span class="mini-card-copy"><strong>${title}</strong><small>${note}</small></span></button>`).join('')}
    </section>
    <section class="home-notice"><span>ⓘ</span><p>页面内数据、价格和订单均为前端演示，不会产生真实费用。</p></section>`;
}

function renderLedger(type) {
  const ledger = data.ledgers[type] || data.ledgers.coin;
  app.innerHTML = `${pageHead(`${ledger.title}明细`, '<span></span>')}
    <section class="ledger-hero"><span>可用${ledger.title}</span><strong>${ledger.balance.toLocaleString('zh-CN')}</strong><div><button data-toast="充值功能为前端演示">充值</button><button data-toast="兑换功能为前端演示">兑换</button></div></section>
    <div class="section-head"><h2>收支明细</h2><button data-toast="已显示最近30天记录">最近30天⌄</button></div>
    <section class="plain-card ledger-list">${ledger.records.map(([name, amount, time]) => `<div><span><strong>${name}</strong><small>${time}</small></span><b class="${amount.startsWith('+') ? 'income' : ''}">${amount}</b></div>`).join('')}</section>`;
}

function renderKtvBusiness() {
  const counts = state.ktvRooms.reduce((result, room) => ({ ...result, [room[1]]: (result[room[1]] || 0) + 1 }), {});
  app.innerHTML = `${pageHead('KTV 业务')}
    <section class="business-hero"><img src="${image('ktv-1.png')}" alt="A380 KTV"><div><small>今日营业额</small><strong>¥8,680</strong><p>较昨日 +12.6%</p></div></section>
    <section class="metric-grid"><button data-toast="显示今日全部订单"><strong>18</strong><span>今日订单</span></button><button data-toast="显示使用中包厢"><strong>${counts['占用'] || 0}</strong><span>使用中</span></button><button data-toast="显示预订客户"><strong>${counts['预定'] || 0}</strong><span>待到店</span></button><button data-toast="显示待处理包厢"><strong>${(counts['清理中'] || 0)+(counts['维护'] || 0)}</strong><span>待处理</span></button></section>
    <div class="section-head"><h2>快捷操作</h2><span></span></div>
    <section class="quick-grid"><button data-toast="已打开预订登记（mock）"><span>📅</span>预订登记</button><button data-toast="已打开组合收银（mock）"><span>💳</span>前台收银</button><button data-toast="交接班数据已生成（mock）"><span>🔁</span>交接班</button><button data-toast="今日业绩 ¥8,680，套餐销售12份"><span>📊</span>经营报表</button></section>
    <div class="section-head"><h2>包厢状态</h2><button data-toast="状态数据已刷新">刷新 ›</button></div>
    <div class="status-legend"><span>● 空闲</span><span>● 预定</span><span>● 占用</span><span>● 清理中</span><span>● 维护</span></div>
    <section class="room-grid">${state.ktvRooms.map((room,index) => `<button class="room-card status-${room[2]}" data-route="business-room/${index}"><span>${room[0]}</span><strong>${room[1]}</strong><small>${room[1] === '占用' ? '已用 01:36' : room[1] === '预定' ? '20:30到店' : '点击处理'}</small></button>`).join('')}</section>`;
}

function renderKtvRoom(index = 0) {
  const room = state.ktvRooms[index] || state.ktvRooms[0];
  const actions = {
    '空闲': [['open','开台']], '预定': [['arrive','确认到店'],['cancel','取消预留']],
    '占用': [['renew','续台'],['transfer','转台'],['settle','结账']],
    '清理中': [['clean','完成清理']], '维护': [['repair','完成维护']],
  }[room[1]] || [];
  app.innerHTML = `${pageHead(room[0], '<span></span>')}
    <section class="room-detail"><img src="${image(`ktv-${(index % 4) + 1}.png`)}" alt="${room[0]}"><div><span class="room-status status-${room[2]}">${room[1]}</span><h2>${room[0]}</h2><p>容纳 4-6 人 · 包厢低消 ¥298</p></div></section>
    ${room[1] === '占用' ? '<section class="detail-card session-info"><div><span>客户</span><strong>王先生 · 138****6688</strong></div><div><span>开台时间</span><strong>19:20</strong></div><div><span>已用时长</span><strong>01:36</strong></div><div><span>当前消费</span><strong class="price">¥468</strong></div></section>' : ''}
    <section class="detail-card"><h3>包厢备注</h3><p>${room[1] === '预定' ? '客户预订生日聚会套餐，前台需提前电话确认到店时间。' : '设备检查正常，酒水库存充足。'}</p></section>
    <div class="room-actions">${actions.map(([action,label]) => `<button class="primary-button" data-room-action="${action}" data-room-index="${index}">${label}</button>`).join('')}</div>`;
}

function venueCards(category) {
  const venue = data.venues[category];
  const sort = state.venueSort[category] || 'smart';
  let rows = venue.names.map((name, index) => ({
    index, name, image: venue.images[index % venue.images.length], rating: 4.9 - index * .1,
    sold: 1286 - index * 172, distance: .8 + index * .6,
    price: venue.packages[0].price + index * 20,
  }));
  if (sort === 'near') rows.sort((a,b) => a.distance - b.distance);
  if (sort === 'rating') rows.sort((a,b) => b.rating - a.rating);
  if (sort === 'price') rows.sort((a,b) => a.price - b.price);
  return rows;
}

function renderVenueList(category) {
  const venue = data.venues[category];
  if (!venue) return renderHome();
  const sort = state.venueSort[category] || 'smart';
  const chips = [['smart','智能排序'],['near','附近优先'],['rating','评分最高'],['price','价格最低']];
  app.innerHTML = `${pageHead(venue.title)}
    <input class="search" id="venue-search" placeholder="${venue.search}" aria-label="${venue.search}" />
    <div class="chips">${chips.map(([id,label]) => `<button class="chip ${sort === id ? 'active' : ''}" data-venue-sort="${id}" data-category="${category}">${label}</button>`).join('')}</div>
    <section class="list" id="venue-list">${venueCards(category).map(item => `
      <article class="venue-card" data-route="venue/${category}/${item.index}">
        <img src="${image(item.image)}" alt="${item.name}">
        <div class="venue-copy"><h3>${item.name}</h3><p><span class="rating">★ ${item.rating.toFixed(1)}</span> · 已售 ${item.sold}</p><p class="ellipsis">${venue.tags.join(' · ')}</p><p><span class="price">${money(item.price)}起</span> · 距离 ${item.distance.toFixed(1)}km</p></div>
      </article>`).join('')}</section>`;
  document.querySelector('#venue-search').addEventListener('input', event => {
    const query = event.target.value.trim().toLowerCase();
    document.querySelectorAll('.venue-card').forEach(card => card.hidden = query && !card.textContent.toLowerCase().includes(query));
  });
}

function renderVenueDetail(category, venueIndex = 0) {
  const venue = data.venues[category];
  const name = venue.names[venueIndex] || venue.names[0];
  app.innerHTML = `${pageHead(venue.title)}
    <section class="gallery"><img id="gallery-main" src="${image(venue.images[venueIndex % venue.images.length])}" alt="${name}"><div class="gallery-count">${venue.images.length}张</div></section>
    <section class="detail-card merchant"><h2>${name}</h2><p><span class="rating">★ 4.9</span>　环境4.9　服务4.8</p><div class="tag-row">${venue.tags.map(tag => `<span>${tag}</span>`).join('')}</div><p class="address">📍 ${venue.address}<button data-toast="已复制地址">复制</button></p></section>
    <div class="section-head"><h2>优惠套餐</h2><button data-toast="价格均为前端模拟">价格说明 ›</button></div>
    <section class="package-list">${venue.packages.map((pkg, index) => `<article class="package-card"><div><h3>${pkg.name}</h3><p>${pkg.desc}</p><small>随时退 · 过期自动退 · 剩余${pkg.stock}份</small></div><aside><strong>${money(pkg.price)}</strong><button data-route="book/${category}/${venueIndex}/${index}">预订</button></aside></article>`).join('')}</section>
    <div class="section-head"><h2>环境照片</h2><span></span></div>
    <div class="photo-strip">${venue.images.map(pic => `<button data-gallery="${image(pic)}"><img src="${image(pic)}" alt="${name}环境"></button>`).join('')}</div>
    <section class="detail-card"><h3>购买须知</h3><p>本页面为前端 mock 演示；请按预约时间到店，实际服务内容以门店确认为准。</p></section>`;
}

function renderBooking(category, venueIndex = 0, packageIndex = 0) {
  const venue = data.venues[category];
  const pkg = venue.packages[packageIndex];
  const name = venue.names[venueIndex] || venue.names[0];
  app.innerHTML = `${pageHead('填写预订信息', '<span></span>')}
    <section class="summary-card"><img src="${image(venue.images[venueIndex % venue.images.length])}" alt="${name}"><div><h2>${name}</h2><p>${pkg.name}</p><strong>${money(pkg.price)}</strong></div></section>
    <form id="venue-order-form" class="form-stack" data-category="${category}" data-venue="${venueIndex}" data-package="${packageIndex}">
      <section class="form-card"><h2>到店信息</h2>
        <label>${venue.dateLabel}<input required name="date" type="date" min="${dateOffset(0)}" value="${dateOffset(1)}"></label>
        <label>${venue.arrivalLabel}<input required name="time" type="time" value="19:30"></label>
        <label>${category === 'hotel' ? '房间数量' : '选择台位/包间'}<select name="slot">${venue.slots.map(slot => `<option>${slot}</option>`).join('')}</select></label>
      </section>
      <section class="form-card"><h2>预订人信息</h2>
        <label>姓名<input required name="name" autocomplete="name" placeholder="请输入预订人姓名"></label>
        <label>手机号码<input required name="phone" autocomplete="tel" inputmode="tel" pattern="1[0-9]{10}" placeholder="用于接收预订提醒"></label>
        <label>备注<textarea name="remark" rows="2" placeholder="如有特殊需求请填写"></textarea></label>
      </section>
      <p class="mock-notice">提交后仅生成本机 mock 订单，不会产生真实扣款。</p>
      <div class="submit-spacer"></div><footer class="action-bar"><span>合计 <strong>${money(pkg.price)}</strong></span><button class="primary-button" type="submit">提交订单</button></footer>
    </form>`;
}

function renderCatalog(category) {
  const catalog = data.catalogs[category];
  if (!catalog) return renderHome();
  app.innerHTML = `${pageHead(catalog.title, `<button class="head-action" data-route="cart">购物车 ${cartCount() ? `<b>${cartCount()}</b>` : ''}</button>`)}
    <input class="search" id="catalog-search" placeholder="搜索${catalog.title}商品" aria-label="搜索${catalog.title}商品">
    <div class="chips">${catalog.tags.map((tag,index) => `<button class="chip ${index === 0 ? 'active' : ''}" data-toast="已选择：${tag}">${tag}</button>`).join('')}</div>
    <section class="product-grid" id="product-list">${catalog.items.map((item,index) => `
      <article class="product-card"><button class="product-main" data-route="product/${category}/${index}"><img src="${image(item[3])}" alt="${item[0]}"><span><h3>${item[0]}</h3><p>${item[1]}</p><small>月售 ${item[4]} · 好评98%</small></span></button><footer><strong>${money(item[2])}</strong><button data-add="${category}/${index}">${catalog.action}</button></footer></article>`).join('')}</section>
    ${cartCount() ? `<button class="floating-cart" data-route="cart">🛒 已选 ${cartCount()} 件　去结算 ›</button>` : ''}`;
  document.querySelector('#catalog-search').addEventListener('input', event => {
    const query = event.target.value.trim().toLowerCase();
    document.querySelectorAll('.product-card').forEach(card => card.hidden = query && !card.textContent.toLowerCase().includes(query));
  });
}

function productFromKey(key) {
  const [category, rawIndex] = key.split('/');
  const catalog = data.catalogs[category];
  const index = Number(rawIndex);
  return { category, index, catalog, item: catalog?.items[index] };
}
function cartCount() { return Object.values(state.cart).reduce((sum, count) => sum + count, 0); }
function cartTotal() {
  return Object.entries(state.cart).reduce((sum, [key, count]) => {
    const product = productFromKey(key);
    return sum + (product.item?.[2] || 0) * count;
  }, 0);
}
function addCart(key, count = 1) {
  state.cart[key] = (state.cart[key] || 0) + count;
  saveLocal('a380-cart', state.cart);
  showToast('已加入购物车');
}

function renderProduct(category, index = 0) {
  const catalog = data.catalogs[category];
  const item = catalog.items[index];
  app.innerHTML = `${pageHead('商品详情', `<button class="head-action" data-route="cart">购物车 ${cartCount() || ''}</button>`)}
    <section class="product-hero"><img src="${image(item[3])}" alt="${item[0]}"></section>
    <section class="detail-card product-detail"><h1>${item[0]}</h1><strong>${money(item[2])}</strong><p>${item[1]}</p><div class="tag-row"><span>随时退</span><span>到店即用</span><span>过期自动退</span></div></section>
    <section class="detail-card"><h3>套餐内容</h3><ul><li>精选主商品 1 份</li><li>专属服务及配套 1 份</li><li>前端 mock 优惠权益</li></ul></section>
    <div class="submit-spacer"></div><footer class="action-bar"><span><small>优惠价</small> <strong>${money(item[2])}</strong></span><div><button class="secondary-button" data-add="${category}/${index}">加入购物车</button><button class="primary-button" data-buy="${category}/${index}">立即购买</button></div></footer>`;
}

function renderCart() {
  const entries = Object.entries(state.cart).filter(([,count]) => count > 0);
  app.innerHTML = `${pageHead('购物车', '<button class="head-action" data-clear-cart>清空</button>')}
    ${entries.length ? `<section class="cart-list">${entries.map(([key,count]) => {
      const product = productFromKey(key); const item = product.item;
      return `<article class="cart-card"><img src="${image(item[3])}" alt="${item[0]}"><div><h3>${item[0]}</h3><p>${money(item[2])}</p><div class="stepper"><button data-cart-step="${key}" data-delta="-1">−</button><span>${count}</span><button data-cart-step="${key}" data-delta="1">＋</button></div></div></article>`;
    }).join('')}</section><div class="submit-spacer"></div><footer class="action-bar"><span>合计 <strong>${money(cartTotal())}</strong></span><button class="primary-button" data-route="checkout">去结算</button></footer>` : emptyState('🛒','购物车还是空的','去服务首页挑选喜欢的商品吧')}`;
}

function renderCheckout() {
  if (!cartCount()) return renderCart();
  app.innerHTML = `${pageHead('确认订单', '<span></span>')}
    <form id="catalog-order-form" class="form-stack">
      <section class="form-card"><h2>预订人信息</h2><label>姓名<input required name="name" autocomplete="name" placeholder="请输入预订人姓名"></label><label>手机号码<input required name="phone" inputmode="tel" pattern="1[0-9]{10}" placeholder="用于接收订单提醒"></label><label>备注<textarea name="remark" rows="2" placeholder="口味、配送或到店需求"></textarea></label></section>
      <section class="form-card"><h2>商品明细</h2>${Object.entries(state.cart).map(([key,count]) => { const p = productFromKey(key); return `<div class="summary-row"><span>${p.item[0]} × ${count}</span><strong>${money(p.item[2] * count)}</strong></div>`; }).join('')}</section>
      <p class="mock-notice">此页面为前端演示，不会调用支付或产生真实费用。</p>
      <div class="submit-spacer"></div><footer class="action-bar"><span>合计 <strong>${money(cartTotal())}</strong></span><button class="primary-button" type="submit">提交订单</button></footer>
    </form>`;
}

function renderTravelSearch(kind) {
  const isFlight = kind === 'flights';
  const service = serviceById(kind);
  app.innerHTML = `${pageHead(service.name)}
    <section class="travel-hero"><span>${service.icon}</span><div><h2>${isFlight ? '国内机票预订' : '安心出行 · 快速叫车'}</h2><p>${isFlight ? '机场及航班信息均为前端 mock' : '车型、司机和价格均为前端 mock'}</p></div></section>
    <form id="travel-search-form" class="travel-search-form" data-kind="${kind}">
      ${isFlight ? `<div class="route-fields"><label>出发城市<input required name="from" value="${state.travel.from}"></label><button type="button" data-swap-route aria-label="交换出发和到达">⇄</button><label>到达城市<input required name="to" value="${state.travel.to}"></label></div><label>出发日期<input required name="date" type="date" min="${dateOffset(0)}" value="${state.travel.date}"></label><label>乘机人数<select name="people"><option>1成人</option><option>2成人</option><option>2成人 1儿童</option></select></label>` : `<label>上车地点<input required name="pickup" value="${state.travel.pickup}"></label><button class="location-button" type="button" data-toast="已使用 mock 定位：深圳宝安国际机场 T3">◎ 使用当前位置</button><label>目的地<input required name="dropoff" value="${state.travel.dropoff}"></label><label>用车时间<input required name="dateTime" type="datetime-local" value="${dateOffset(1)}T09:30"></label>`}
      <button class="primary-button search-submit" type="submit">${isFlight ? '查询机票' : '立即叫车'}</button>
    </form>
    <section class="travel-benefits"><span>✓ 价格透明</span><span>✓ 前端模拟</span><span>✓ 提交即成功</span></section>`;
}

function renderTravelResults(kind) {
  const isFlight = kind === 'flights';
  if (isFlight) {
    app.innerHTML = `${pageHead(`${state.travel.from}-${state.travel.to}`)}
      <div class="date-strip">${[-1,0,1,2].map(offset => { const value = new Date(`${state.travel.date}T00:00:00`); value.setDate(value.getDate()+offset); const date = value.toISOString().slice(0,10); return `<button class="${offset===0?'active':''}" data-flight-date="${date}"><span>${offset===0?'出发':'可选'}</span><strong>${formatDate(date)}</strong><small>${money(558+Math.abs(offset)*22)}起</small></button>`; }).join('')}</div>
      <div class="chips"><button class="chip active">智能排序</button><button class="chip">价格最低</button><button class="chip">出发最早</button><button class="chip">仅看直飞</button></div>
      <section class="flight-list">${data.flights.map((flight,index) => `<article class="flight-card" data-route="travel-detail/flights/${index}"><div class="flight-times"><span><strong>${flight.start}</strong><small>${flight.from}</small></span><i>${flight.duration}${flight.direct?' · 直飞':' · 中转'}</i><span><strong>${flight.end}</strong><small>${flight.to}</small></span></div><footer><span>${flight.airline} ${flight.id} · ${flight.model}</span><strong>${money(flight.price)}</strong></footer></article>`).join('')}</section>`;
  } else {
    app.innerHTML = `${pageHead('选择车型')}
      <section class="route-summary"><span>●</span><div><strong>${escapeHtml(state.travel.pickup)}</strong><i></i><strong>${escapeHtml(state.travel.dropoff)}</strong></div><button data-route="service/taxi">修改</button></section>
      <p class="mock-notice">预计34分钟 · 约26.8公里 · 实际价格以行程为准</p>
      <section class="ride-list">${data.rides.map((ride,index) => `<article class="ride-card"><span class="ride-icon">${ride.icon}</span><div><h3>${ride.name}</h3><p>${ride.car} · ${ride.seats}</p><small>${ride.wait}</small></div><aside><strong>${money(ride.price)}</strong><button data-route="travel-detail/taxi/${index}">选择</button></aside></article>`).join('')}</section>`;
  }
}

function renderTravelDetail(kind, index = 0) {
  const isFlight = kind === 'flights';
  if (!isFlight) {
    const ride = data.rides[index];
    app.innerHTML = `${pageHead('行程详情')}
      <section class="detail-card ride-detail"><span>${ride.icon}</span><h2>${ride.name}</h2><p>${ride.car} · ${ride.seats} · ${ride.wait}</p><div class="tag-row"><span>专业司机</span><span>免费取消</span><span>行程保障</span></div></section>
      <section class="route-summary large"><span>●</span><div><strong>${escapeHtml(state.travel.pickup)}</strong><i></i><strong>${escapeHtml(state.travel.dropoff)}</strong></div></section>
      <section class="detail-card"><h3>服务包含</h3><ul><li>专业司机接驾服务</li><li>基础高速费与平台服务费</li><li>行程取消及延误保障</li></ul></section>
      <div class="submit-spacer"></div><footer class="action-bar"><span>预估 <strong>${money(ride.price)}</strong></span><button class="primary-button" data-route="travel-order/taxi/${index}/0">填写预订人</button></footer>`;
    return;
  }
  const flight = data.flights[index];
  const fares = [['经济舱优选', flight.price],['经济舱灵活', flight.price+65],['公务舱', flight.price+860]];
  app.innerHTML = `${pageHead('航班详情')}
    <section class="flight-detail"><h2>${state.travel.from} → ${state.travel.to}</h2><div class="flight-times"><span><strong>${flight.start}</strong><small>${flight.from}</small></span><i>${flight.duration}${flight.direct?' · 直飞':' · 经停'}</i><span><strong>${flight.end}</strong><small>${flight.to}</small></span></div><p>${flight.airline} ${flight.id} · ${flight.model}</p></section>
    <div class="section-head"><h2>选择舱位</h2><span></span></div>
    <section class="fare-list">${fares.map(([name,price],fareIndex) => `<article><div><h3>${name}</h3><p>行李额20KG · 可开发票 · 退改${fareIndex?'灵活':'有条件'}</p></div><aside><strong>${money(price)}</strong><button data-route="travel-order/flights/${index}/${fareIndex}">订</button></aside></article>`).join('')}</section>`;
}

function renderTravelOrder(kind, index = 0, fareIndex = 0) {
  const isFlight = kind === 'flights';
  const option = isFlight ? data.flights[index] : data.rides[index];
  const price = isFlight ? option.price + [0,65,860][fareIndex] : option.price;
  app.innerHTML = `${pageHead('填写订单', '<span></span>')}
    <section class="trip-summary"><strong>${isFlight ? `${state.travel.from} → ${state.travel.to}` : `${state.travel.pickup} → ${state.travel.dropoff}`}</strong><p>${isFlight ? `${option.airline} ${option.id} · ${option.start}-${option.end}` : `${option.name} · ${option.car}`}</p><span>${money(price)}</span></section>
    <form id="travel-order-form" class="form-stack" data-kind="${kind}" data-index="${index}" data-fare="${fareIndex}" data-price="${price}">
      <section class="form-card"><h2>${isFlight ? '乘机人信息' : '预订人信息'}</h2><label>姓名<input required name="name" autocomplete="name" placeholder="请填写真实姓名"></label>${isFlight ? '<label>身份证号<input required name="idNumber" inputmode="text" minlength="15" maxlength="18" placeholder="用于乘机实名认证"></label>' : ''}<label>手机号码<input required name="phone" inputmode="tel" pattern="1[0-9]{10}" placeholder="用于接收订单信息"></label><label>备注<textarea name="remark" rows="2" placeholder="选填"></textarea></label></section>
      <p class="mock-notice">机场、航班、车辆和价格信息均为 mock，提交后直接显示成功。</p>
      <div class="submit-spacer"></div><footer class="action-bar"><span>合计 <strong>${money(price)}</strong></span><button class="primary-button" type="submit">提交订单</button></footer>
    </form>`;
}

function renderSuccess(order) {
  app.innerHTML = `${pageHead('提交成功', '<span></span>')}
    <section class="success"><div>✓</div><h1>预订成功</h1><p>订单已生成，我们会提前与您对接确认。</p></section>
    <section class="plain-card success-summary"><div><span>订单编号</span><strong>${order.number}</strong></div><div><span>预订项目</span><strong>${escapeHtml(order.title)}</strong></div><div><span>预订人</span><strong>${escapeHtml(order.name)}</strong></div><div><span>订单金额</span><strong>${money(order.amount)}</strong></div><div><span>订单状态</span><strong class="income">${order.status}</strong></div></section>
    <div class="success-actions"><button class="secondary-button" data-route="orders">查看订单</button><button class="primary-button" data-route="home">返回服务首页</button></div>`;
}

function renderOrders() {
  app.innerHTML = `${pageHead('我的订单', '<span></span>')}
    <div class="chips"><button class="chip active">全部</button><button class="chip">待到店</button><button class="chip">已完成</button><button class="chip">已取消</button></div>
    ${state.orders.length ? `<section class="order-list">${state.orders.map(order => `<article><header><span>${order.type}</span><strong>${order.status}</strong></header><h3>${escapeHtml(order.title)}</h3><p>订单号 ${order.number}</p><footer><span>${order.createdAt}</span><b>${money(order.amount)}</b></footer></article>`).join('')}</section>` : emptyState('🧾','还没有订单','从服务首页选择项目并提交后，会显示在这里')}`;
}

function render() {
  const route = location.hash.replace(/^#\/?/, '') || 'home';
  const parts = route.split('/');
  window.scrollTo(0, 0);
  if (route === 'home') return renderHome();
  if (route === 'orders') return renderOrders();
  if (route === 'cart') return renderCart();
  if (route === 'checkout') return renderCheckout();
  if (parts[0] === 'ledger') return renderLedger(parts[1]);
  if (parts[0] === 'venue') return renderVenueDetail(parts[1], Number(parts[2] || 0));
  if (parts[0] === 'book') return renderBooking(parts[1], Number(parts[2] || 0), Number(parts[3] || 0));
  if (parts[0] === 'product') return renderProduct(parts[1], Number(parts[2] || 0));
  if (parts[0] === 'travel-results') return renderTravelResults(parts[1]);
  if (parts[0] === 'travel-detail') return renderTravelDetail(parts[1], Number(parts[2] || 0));
  if (parts[0] === 'travel-order') return renderTravelOrder(parts[1], Number(parts[2] || 0), Number(parts[3] || 0));
  if (parts[0] === 'business-room') return renderKtvRoom(Number(parts[1] || 0));
  if (parts[0] === 'service') {
    const service = serviceById(parts[1]);
    if (!service) return renderHome();
    if (service.kind === 'venue') return renderVenueList(service.id);
    if (service.kind === 'catalog') return renderCatalog(service.id);
    if (service.kind === 'business') return renderKtvBusiness();
    return renderTravelSearch(service.id);
  }
  renderHome();
}

document.addEventListener('click', event => {
  const route = event.target.closest('[data-route]')?.dataset.route;
  if (route) return go(route);
  if (event.target.closest('[data-back]')) {
    if (location.hash && location.hash !== '#/home' && history.length > 1) history.back();
    else go('home');
    return;
  }
  const message = event.target.closest('[data-toast]')?.dataset.toast;
  if (message) return showToast(message);
  const sortButton = event.target.closest('[data-venue-sort]');
  if (sortButton) {
    state.venueSort[sortButton.dataset.category] = sortButton.dataset.venueSort;
    return renderVenueList(sortButton.dataset.category);
  }
  const gallery = event.target.closest('[data-gallery]');
  if (gallery) document.querySelector('#gallery-main').src = gallery.dataset.gallery;
  const addButton = event.target.closest('[data-add]');
  if (addButton) {
    addCart(addButton.dataset.add);
    const routeParts = location.hash.split('/');
    if (routeParts[1] === 'service') renderCatalog(routeParts[2]);
    return;
  }
  const buyButton = event.target.closest('[data-buy]');
  if (buyButton) { addCart(buyButton.dataset.buy); return go('cart'); }
  const step = event.target.closest('[data-cart-step]');
  if (step) {
    const key = step.dataset.cartStep;
    state.cart[key] = Math.max(0, (state.cart[key] || 0) + Number(step.dataset.delta));
    if (!state.cart[key]) delete state.cart[key];
    saveLocal('a380-cart', state.cart); return renderCart();
  }
  if (event.target.closest('[data-clear-cart]')) {
    state.cart = {}; saveLocal('a380-cart', state.cart); return renderCart();
  }
  if (event.target.closest('[data-swap-route]')) {
    const from = document.querySelector('[name="from"]'); const to = document.querySelector('[name="to"]');
    [from.value, to.value] = [to.value, from.value];
  }
  const dateButton = event.target.closest('[data-flight-date]');
  if (dateButton) { state.travel.date = dateButton.dataset.flightDate; renderTravelResults('flights'); }
  const roomAction = event.target.closest('[data-room-action]');
  if (roomAction) {
    const room = state.ktvRooms[Number(roomAction.dataset.roomIndex)];
    const next = { open: ['占用','蓝色'], arrive: ['占用','蓝色'], cancel: ['空闲','绿色'], settle: ['清理中','紫色'], clean: ['空闲','绿色'], repair: ['空闲','绿色'] }[roomAction.dataset.roomAction];
    if (next) { room[1] = next[0]; room[2] = next[1]; showToast('包厢状态已更新'); }
    else showToast(roomAction.dataset.roomAction === 'renew' ? '已续台1小时' : '转台功能已完成（mock）');
    renderKtvRoom(Number(roomAction.dataset.roomIndex));
  }
});

document.addEventListener('submit', event => {
  event.preventDefault();
  const form = event.target;
  if (!form.reportValidity()) return;
  const fields = Object.fromEntries(new FormData(form));
  if (form.id === 'travel-search-form') {
    const kind = form.dataset.kind;
    Object.assign(state.travel, fields);
    return go(`travel-results/${kind}`);
  }
  if (form.id === 'venue-order-form') {
    const category = form.dataset.category;
    const venue = data.venues[category];
    const pkg = venue.packages[Number(form.dataset.package)];
    const order = {
      number: orderNo(), type: venue.title, title: `${venue.names[Number(form.dataset.venue)]} · ${pkg.name}`,
      name: fields.name, amount: pkg.price, status: '预订成功', createdAt: new Date().toLocaleString('zh-CN'),
    };
    addOrder(order); renderSuccess(order); return;
  }
  if (form.id === 'catalog-order-form') {
    const order = { number: orderNo(), type: '商品订单', title: `A380服务商品 ${cartCount()}件`, name: fields.name, amount: cartTotal(), status: '提交成功', createdAt: new Date().toLocaleString('zh-CN') };
    addOrder(order); state.cart = {}; saveLocal('a380-cart', state.cart); renderSuccess(order); return;
  }
  if (form.id === 'travel-order-form') {
    const kind = form.dataset.kind; const index = Number(form.dataset.index);
    const option = kind === 'flights' ? data.flights[index] : data.rides[index];
    const order = {
      number: orderNo(), type: kind === 'flights' ? '机票' : '打车',
      title: kind === 'flights' ? `${state.travel.from}-${state.travel.to} · ${option.airline}${option.id}` : `${state.travel.pickup}-${state.travel.dropoff} · ${option.name}`,
      name: fields.name, amount: Number(form.dataset.price), status: '预订成功', createdAt: new Date().toLocaleString('zh-CN'),
    };
    addOrder(order); renderSuccess(order);
  }
});

window.addEventListener('hashchange', render);
render();
