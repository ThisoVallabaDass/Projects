const state = {
  roleMode: 'BUYER',
  activeTab: 'login',
  currentView: 'home',
  token: localStorage.getItem('tinytrail_token'),
  user: JSON.parse(localStorage.getItem('tinytrail_user') || 'null'),
  vendorProfile: null,
  shiftStarted: false,
};

const el = (id) => document.getElementById(id);

const api = async (path, options = {}) => {
  const headers = { ...(options.headers || {}) };
  if (state.token) {
    headers.Authorization = `Bearer ${state.token}`;
  }

  const response = await fetch(path, { ...options, headers });
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;

  if (!response.ok) {
    throw new Error(data?.error || data?.details || 'Request failed');
  }

  return data;
};

const persistAuth = () => {
  if (state.token && state.user) {
    localStorage.setItem('tinytrail_token', state.token);
    localStorage.setItem('tinytrail_user', JSON.stringify(state.user));
  } else {
    localStorage.removeItem('tinytrail_token');
    localStorage.removeItem('tinytrail_user');
  }
};

const setMessage = (message, isError = false) => {
  const node = el('authMessage');
  node.textContent = message;
  node.style.color = isError ? '#b42318' : '#0f4ca8';
};

const setTheme = (role) => {
  document.body.classList.toggle('theme-vendor', role === 'SELLER');
  document.body.classList.toggle('theme-customer', role !== 'SELLER');
};

const setApiStatus = async () => {
  const badge = el('apiStatusBadge');
  try {
    await api('/api/health');
    badge.textContent = 'API Online';
    badge.style.background = '#e7f7ec';
    badge.style.color = '#14532d';
  } catch (_error) {
    badge.textContent = 'API Offline';
    badge.style.background = '#fde8e8';
    badge.style.color = '#b42318';
  }
};

const setRoleMode = (role) => {
  state.roleMode = role;
  const isVendor = role === 'SELLER';
  el('customerModeBtn').classList.toggle('active', !isVendor);
  el('vendorModeBtn').classList.toggle('active', isVendor);
  el('loginSubmitBtn').textContent = isVendor ? 'Login as vendor' : 'Login as customer';
  el('registerSubmitBtn').textContent = isVendor ? 'Create vendor account' : 'Create customer account';
  el('authTitle').textContent = isVendor ? 'Vendor login and signup' : 'Customer login and signup';
  setTheme(role);
};

const setActiveTab = (tab) => {
  state.activeTab = tab;
  el('loginTabBtn').classList.toggle('active', tab === 'login');
  el('registerTabBtn').classList.toggle('active', tab === 'register');
  el('loginForm').classList.toggle('hidden', tab !== 'login');
  el('registerForm').classList.toggle('hidden', tab !== 'register');
};

const setCurrentView = (view) => {
  state.currentView = view;

  ['navHome', 'navProducts', 'navStudio', 'navProfile'].forEach((id) => {
    const node = el(id);
    if (node) {
      node.classList.toggle('active', node.dataset.view === view);
    }
  });

  const customerHome = el('customerHomeSection');
  const vendorHome = el('vendorHomeSection');
  const vendorStudio = el('vendorStudioSection');
  const profile = el('profileSection');

  customerHome.classList.add('hidden');
  vendorHome.classList.add('hidden');
  vendorStudio.classList.add('hidden');
  profile.classList.add('hidden');

  if (!state.user) {
    return;
  }

  if (state.user.role === 'SELLER') {
    if (view === 'profile') {
      profile.classList.remove('hidden');
    } else if (view === 'studio' || view === 'products') {
      vendorStudio.classList.remove('hidden');
    } else {
      vendorHome.classList.remove('hidden');
    }
  } else {
    if (view === 'profile') {
      profile.classList.remove('hidden');
    } else {
      customerHome.classList.remove('hidden');
    }
  }
};

const renderProductCards = (targetId, products) => {
  const target = el(targetId);
  if (!products.length) {
    target.className = 'cards-grid empty-state';
    target.innerHTML = '<p>No products found yet.</p>';
    return;
  }

  target.className = 'cards-grid';
  target.innerHTML = products
    .map((product) => {
      const imageUrl = product.image_url || product.imageUrl;
      return `
        <article class="product-card">
          ${imageUrl ? `<img src="${imageUrl}" alt="${product.name}" />` : ''}
          <h4>${product.name}</h4>
          <p>${product.description || 'No description provided.'}</p>
          <div class="product-meta">
            <span>Rs. ${Number(product.price || 0).toFixed(2)}</span>
            <span>${product.vendor_name || product.shop_name || 'Local Vendor'}</span>
          </div>
        </article>
      `;
    })
    .join('');
};

const updateProfileCard = () => {
  el('profileName').textContent = state.user ? state.user.username : 'Guest';
  el('profileDetails').textContent = state.user
    ? `${state.user.role} • ${state.user.email || 'No email'} • ${state.user.phone || 'No phone'}`
    : 'Login to view account details.';
};

const loadVendorWorkspace = async () => {
  try {
    const vendor = await api('/api/vendors/me');
    state.vendorProfile = vendor;
    el('shopName').value = vendor.shop_name || '';
    el('shopAddress').value = vendor.address || '';
    el('shopPincode').value = vendor.pincode || '';
    el('shopStory').value = vendor.story_text || '';
    await loadVendorProducts();
  } catch (_error) {
    state.vendorProfile = null;
    renderProductCards('vendorProducts', []);
  }
};

const loadVendorProducts = async () => {
  try {
    const products = await api('/api/products/mine');
    renderProductCards('vendorProducts', products);
  } catch (_error) {
    renderProductCards('vendorProducts', []);
  }
};

const validateStoredSession = async () => {
  if (!state.token) return;

  try {
    const user = await api('/api/auth/me');
    state.user = user;
    persistAuth();
  } catch (_error) {
    state.token = null;
    state.user = null;
    persistAuth();
  }
};

const applyAuthState = async () => {
  const guestSection = el('guestSection');
  const accountPanel = el('accountPanel');
  const authForms = el('authForms');
  const logoutButton = el('logoutButton');
  const roleBadge = el('roleBadge');
  const webNav = el('webNav');
  const workspaceTitle = el('workspaceTitle');
  const accountName = el('accountName');
  const accountMeta = el('accountMeta');

  updateProfileCard();

  if (!state.token || !state.user) {
    setTheme(state.roleMode);
    authForms.classList.remove('hidden');
    accountPanel.classList.add('hidden');
    logoutButton.classList.add('hidden');
    roleBadge.classList.add('hidden');
    webNav.classList.add('hidden');
    guestSection.classList.remove('hidden');
    workspaceTitle.textContent = 'Choose a mode and sign in';
    setCurrentView('home');
    return;
  }

  setTheme(state.user.role);
  setRoleMode(state.user.role);
  authForms.classList.add('hidden');
  accountPanel.classList.remove('hidden');
  logoutButton.classList.remove('hidden');
  roleBadge.classList.remove('hidden');
  webNav.classList.remove('hidden');
  guestSection.classList.add('hidden');

  accountName.textContent = state.user.username;
  accountMeta.textContent = `${state.user.role} • ${state.user.email || ''}`;
  roleBadge.textContent = state.user.role;
  workspaceTitle.textContent = `Welcome, ${state.user.username}`;

  el('navStudio').classList.toggle('hidden', state.user.role !== 'SELLER');
  setCurrentView(state.user.role === 'SELLER' ? 'home' : 'home');

  if (state.user.role === 'SELLER') {
    await loadVendorWorkspace();
  }
};

el('customerModeBtn').addEventListener('click', () => setRoleMode('BUYER'));
el('vendorModeBtn').addEventListener('click', () => setRoleMode('SELLER'));
el('loginTabBtn').addEventListener('click', () => setActiveTab('login'));
el('registerTabBtn').addEventListener('click', () => setActiveTab('register'));
el('switchAccountBtn').addEventListener('click', async () => {
  state.token = null;
  state.user = null;
  state.vendorProfile = null;
  persistAuth();
  setMessage('Switched account. Login with a different user.');
  await applyAuthState();
});

[
  ['navHome', 'home'],
  ['navProducts', 'products'],
  ['navStudio', 'studio'],
  ['navProfile', 'profile'],
].forEach(([id, view]) => {
  const node = el(id);
  node.dataset.view = view;
  node.addEventListener('click', () => setCurrentView(view));
});

el('sampleCustomerBtn').addEventListener('click', () => {
  setRoleMode('BUYER');
  setActiveTab('login');
  el('loginIdentifier').value = '9876543211';
  el('loginPassword').value = 'password123';
});

el('sampleVendorBtn').addEventListener('click', () => {
  setRoleMode('SELLER');
  setActiveTab('login');
  el('loginIdentifier').value = '9876543212';
  el('loginPassword').value = 'password123';
});

el('loginForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  setMessage('Logging in...');

  try {
    const data = await api('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        identifier: el('loginIdentifier').value.trim(),
        password: el('loginPassword').value,
      }),
    });

    state.token = data.token;
    state.user = data.user;
    persistAuth();
    setMessage('Login successful.');
    await applyAuthState();
  } catch (error) {
    setMessage(error.message, true);
  }
});

el('registerForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  setMessage('Creating account...');

  try {
    const data = await api('/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: el('registerUsername').value.trim(),
        email: el('registerEmail').value.trim(),
        phone: el('registerPhone').value.trim(),
        password: el('registerPassword').value,
        role: state.roleMode,
      }),
    });

    state.token = data.token;
    state.user = data.user;
    persistAuth();
    setMessage('Account created successfully.');
    await applyAuthState();
  } catch (error) {
    setMessage(error.message, true);
  }
});

el('logoutButton').addEventListener('click', async () => {
  state.token = null;
  state.user = null;
  state.vendorProfile = null;
  state.shiftStarted = false;
  persistAuth();
  setMessage('Logged out.');
  await applyAuthState();
});

el('searchForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  const pincode = el('searchPincode').value.trim();
  if (!pincode) {
    setMessage('Enter a pincode first.', true);
    return;
  }

  try {
    const products = await api(`/api/products/search?pincode=${encodeURIComponent(pincode)}`);
    renderProductCards('productResults', products);
    setMessage(`Loaded ${products.length} product(s) for pincode ${pincode}.`);
  } catch (error) {
    setMessage(error.message, true);
  }
});

el('vendorForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  try {
    const vendor = await api('/api/vendors/onboard', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        shop_name: el('shopName').value.trim(),
        address: el('shopAddress').value.trim(),
        pincode: el('shopPincode').value.trim(),
        story_text: el('shopStory').value.trim(),
      }),
    });

    state.vendorProfile = vendor;
    setMessage('Vendor profile saved.');
    await loadVendorWorkspace();
  } catch (error) {
    setMessage(error.message, true);
  }
});

el('productForm').addEventListener('submit', async (event) => {
  event.preventDefault();

  const formData = new FormData();
  formData.append('name', el('productName').value.trim());
  formData.append('description', el('productDescription').value.trim());
  formData.append('price', el('productPrice').value.trim());
  formData.append('pincode', el('shopPincode').value.trim());
  formData.append('category', el('productCategory').value.trim() || 'General');

  const imageInput = el('productImage');
  const imageFile = imageInput.files[0];
  if (imageFile) {
    formData.append('image', imageFile);
  }

  try {
    await api('/api/products', {
      method: 'POST',
      body: formData,
    });

    el('productForm').reset();
    setMessage('Product added successfully.');
    await loadVendorProducts();
  } catch (error) {
    setMessage(error.message, true);
  }
});

el('refreshVendorProductsBtn').addEventListener('click', async () => {
  await loadVendorProducts();
  setMessage('Vendor products refreshed.');
});

el('toggleShiftBtn').addEventListener('click', () => {
  state.shiftStarted = !state.shiftStarted;
  el('shiftStatusText').textContent = state.shiftStarted
    ? 'Shift started. You are marked live for nearby customers.'
    : 'Currently offline. Start your shift when ready.';
  el('toggleShiftBtn').textContent = state.shiftStarted ? 'End Shift' : 'Start My Shift';
});

(async () => {
  setRoleMode('BUYER');
  setActiveTab('login');
  await validateStoredSession();
  await setApiStatus();
  await applyAuthState();
})();
