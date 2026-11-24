
$(function(){

  const products=[
    {name:"Corrugated box - Large",code:"PKG-001",category:"Packaging",price:24.5,minimum:100,quantity:420,icon:"bi-box"},
    {name:"Bubble wrap roll",code:"PKG-002",category:"Packaging",price:85,minimum:50,quantity:28,icon:"bi-layers"},
    {name:"Thermal label roll",code:"OFF-014",category:"Office supplies",price:120,minimum:40,quantity:18,icon:"bi-receipt"},
    {name:"Packing tape - Clear",code:"PKG-003",category:"Packaging",price:32,minimum:80,quantity:160,icon:"bi-bandaid"},
    {name:"Wireless barcode scanner",code:"ELC-006",category:"Electronics",price:1850,minimum:10,quantity:6,icon:"bi-upc-scan"},
    {name:"Copy paper A4",code:"OFF-008",category:"Office supplies",price:245,minimum:30,quantity:92,icon:"bi-file-earmark"},
    {name:"Disinfectant cleaner",code:"CLN-004",category:"Cleaning",price:95,minimum:35,quantity:12,icon:"bi-droplet"},
    {name:"Plastic storage bin",code:"PKG-011",category:"Packaging",price:175,minimum:25,quantity:64,icon:"bi-inboxes"}
  ];

  const suppliers=[
    {name:"Greenline Packaging Co.",contact:"Mika Santos",phone:"+63 917 234 5678",email:"orders@greenline.example"},
    {name:"Metro Office Essentials",contact:"Paolo Reyes",phone:"+63 918 345 6789",email:"sales@metrooffice.example"},
    {name:"Northstar Industrial Supply",contact:"Angela Cruz",phone:"+63 919 456 7890",email:"hello@northstar.example"},
    {name:"Brightway Trading",contact:"Joshua Lim",phone:"+63 920 567 8901",email:"team@brightway.example"}
  ];

  let transactions=[
    {id:"TRX-00248",type:"Stock in",date:"Nov 24, 2026",reference:"PO-2026-118",items:4,status:"Completed"},
    {id:"TRX-00247",type:"Stock out",date:"Nov 24, 2026",reference:"REQ-2026-064",items:2,status:"Completed"},
    {id:"TRX-00246",type:"Stock in",date:"Nov 23, 2026",reference:"PO-2026-117",items:3,status:"Pending"},
    {id:"TRX-00245",type:"Stock out",date:"Nov 22, 2026",reference:"REQ-2026-063",items:1,status:"Completed"},
    {id:"TRX-00244",type:"Stock in",date:"Nov 21, 2026",reference:"PO-2026-116",items:5,status:"Completed"}
  ];

  const money=n=>"₱"+Number(n).toLocaleString("en-PH",{
    minimumFractionDigits:2,
    maximumFractionDigits:2
  });

  const statusFor=p=>p.quantity<=p.minimum*.5?"critical":
    p.quantity<=p.minimum?"low":"healthy";

  const productCell=p=>'<div class="product-name-cell"><span class="product-thumb"><i class="bi '+p.icon+'"></i></span>'+escapeHtml(p.name)+'</div>';

  function escapeHtml(s){
    return String(s).replace(/[&<>"']/g,c=>({
      "&":"&amp;",
      "<":"&lt;",
      ">":"&gt;",
      '"':"&quot;",
      "'":"&#39;"
    }[c]));
  }

  function transactionRows(rows,withRef){
    return rows.map(t=>
      '<tr><td><span class="id-text">'+t.id+'</span></td>'+
      '<td><span class="type-pill '+(t.type==="Stock in"?"in":"out")+'">'+
      '<i class="bi '+(t.type==="Stock in"?"bi-arrow-down-left":"bi-arrow-up-right")+'"></i>'+
      t.type+'</span></td>'+
      '<td>'+t.date+'</td>'+
      (withRef?'<td>'+escapeHtml(t.reference)+'</td>':'')+
      '<td>'+t.items+' items</td>'+
      '<td><span class="status-pill '+t.status.toLowerCase()+'">'+t.status+'</span></td></tr>'
    ).join("");
  }

  function renderDashboard(){

    $("#recentTransactions").html(
      transactionRows(transactions.slice(0,4),false)
    );

    const low=products.filter(p=>statusFor(p)!=="healthy");

    $("#lowStockList").html(
      low.slice(0,4).map(p=>
        '<div class="low-stock-item">'+
        productCell(p)+
        '<div class="low-stock-info"><strong>'+escapeHtml(p.name)+'</strong>'+
        '<small>Minimum: '+p.minimum+' boxes</small></div>'+
        '<span class="stock-qty">'+p.quantity+'</span></div>'
      ).join("")||'<p class="text-muted small">No low stock items.</p>'
    );

    $("#totalProducts").text(240+products.length);
    $("#productNavCount,#productCount").text(products.length);
    $("#lowStockMetric").text(low.length);
  }

  function renderProducts(){

    const q=($("#productSearch").val()||"").toLowerCase();
    const cat=$("#categoryFilter").val()||"";

    const rows=products.filter(p=>
      (p.name.toLowerCase().includes(q)||p.code.toLowerCase().includes(q))&&
      (!cat||p.category===cat)
    );

    $("#productsTable").html(
      rows.map(p=>
        '<tr><td>'+productCell(p)+'</td>'+
        '<td>'+p.code+'</td>'+
        '<td>'+p.category+'</td>'+
        '<td>'+money(p.price)+'</td>'+
        '<td>'+p.minimum+' boxes</td>'+
        '<td><span class="product-status"><i class="bi bi-circle-fill" style="font-size:6px"></i> Active</span></td>'+
        '<td><button class="icon-btn" title="More"><i class="bi bi-three-dots"></i></button></td></tr>'
      ).join("")||
      '<tr><td colspan="7" class="empty-row">No matching products found.</td></tr>'
    );
  }

  function renderInventory(){

    const q=($("#inventorySearch").val()||"").toLowerCase();
    const filter=$("#stockFilter").val()||"";

    const rows=products.filter(p=>
      (p.name.toLowerCase().includes(q)||p.code.toLowerCase().includes(q))&&
      (!filter||statusFor(p)===filter)
    );

    $("#inventoryTable").html(
      rows.map(p=>{
        const s=statusFor(p);
        const pct=Math.min(100,Math.round(
          p.quantity/Math.max(p.minimum*2,1)*100
        ));

        return '<tr><td>'+productCell(p)+'</td>'+
          '<td>'+p.code+'</td>'+
          '<td><strong>'+p.quantity+'</strong> boxes</td>'+
          '<td>'+p.minimum+' boxes</td>'+
          '<td><span class="stock-bar '+(s==="healthy"?"":s+"bar")+'">'+
          '<span style="width:'+pct+'%"></span></span></td>'+
          '<td><span class="status-pill '+(s==="healthy"?"completed":"pending")+'">'+
          (s==="healthy"?"Healthy":s==="low"?"Low stock":"Critical")+
          '</span></td></tr>';

      }).join("")||
      '<tr><td colspan="6" class="empty-row">No matching inventory records.</td></tr>'
    );
  }

  function renderSuppliers(){

    const q=($("#supplierSearch").val()||"").toLowerCase();

    $("#suppliersTable").html(
      suppliers.filter(s=>
        (s.name+s.contact+s.email).toLowerCase().includes(q)
      ).map(s=>
        '<tr><td><div class="product-name-cell">'+
        '<span class="product-thumb"><i class="bi bi-building"></i></span>'+
        escapeHtml(s.name)+'</div></td>'+
        '<td>'+escapeHtml(s.contact)+'</td>'+
        '<td>'+escapeHtml(s.phone)+'</td>'+
        '<td>'+escapeHtml(s.email)+'</td>'+
        '<td><span class="status-pill completed">Active</span></td></tr>'
      ).join("")||
      '<tr><td colspan="5" class="empty-row">No matching suppliers.</td></tr>'
    );
  }

  function renderTransactions(){

    const q=($("#transactionSearch").val()||"").toLowerCase();
    const type=$("#transactionFilter").val()||"";

    const rows=transactions.filter(t=>
      (t.id+t.reference).toLowerCase().includes(q)&&
      (!type||t.type===type)
    );

    $("#transactionsTable").html(
      transactionRows(rows,true)||
      '<tr><td colspan="6" class="empty-row">No transactions found.</td></tr>'
    );
  }

  function renderAll(){
    renderDashboard();
    renderProducts();
    renderInventory();
    renderSuppliers();
    renderTransactions();
    fillProductSelect();
  }

  function fillProductSelect(){
    $("#transactionProduct").html(
      products.map((p,i)=>
        '<option value="'+i+'">'+escapeHtml(p.name)+' ('+p.quantity+' boxes)</option>'
      ).join("")
    );
  }

  function showToast(msg){
    $("#toastMessage").text(msg);
    bootstrap.Toast.getOrCreateInstance(
      document.getElementById("appToast"),
      {delay:2600}
    ).show();
  }

  function exportCsv(filename,rows){

    const csv=rows.map(r=>
      r.map(v=>'"'+String(v??"").replace(/"/g,'""')+'"').join(",")
    ).join("\n");

    const blob=new Blob(["\ufeff"+csv],{
      type:"text/csv;charset=utf-8;"
    });

    const a=document.createElement("a");
    a.href=URL.createObjectURL(blob);
    a.download=filename;
    a.click();

    URL.revokeObjectURL(a.href);
  }

  function exportProducts(){
    exportCsv("products-preview.csv",[
      ["Product","Code","Category","Unit price","Minimum stock","Quantity"],
      ...products.map(p=>[
        p.name,p.code,p.category,p.price,p.minimum,p.quantity
      ])
    ]);
  }

  function chart(){

    const incoming=[280,390,310,440,360,230,320];
    const outgoing=[190,260,210,300,250,150,220];

    $("#movementChart").html(
      incoming.map((v,i)=>
        '<div class="bar-group">'+
        '<span class="bar in" style="height:'+v/5+'%"></span>'+
        '<span class="bar out" style="height:'+outgoing[i]/5+'%"></span>'+
        '</div>'
      ).join("")
    );
  }

  function navigate(page){

    if(!$("#page-"+page).length)page="dashboard";

    $(".page-view").removeClass("active");
    $("#page-"+page).addClass("active");

    $(".side-nav .nav-link").removeClass("active");

    $('.side-nav .nav-link[data-page="'+page+'"]').addClass("active");

    const title=$('.side-nav .nav-link[data-page="'+page+'"]')
      .find("span").first().text()||"Settings";

    $("#crumbTitle").text(title);
    $("#sidebar").removeClass("open");

    window.location.hash=page;
  }

  // NAVIGATION
  $(document).on("click","[data-page]",function(e){
    e.preventDefault();
    navigate($(this).data("page"));
  });

  $(".side-nav .nav-link").on("click",function(){
    navigate($(this).data("page"));
  });

  $("#menuToggle").on("click",()=>
    $("#sidebar").toggleClass("open")
  );

  // SEARCH AND FILTERS
  $("#productSearch,#categoryFilter").on("input change",renderProducts);

  $("#inventorySearch,#stockFilter").on("input change",renderInventory);

  $("#supplierSearch").on("input",renderSuppliers);

  $("#transactionSearch,#transactionFilter").on("input change",renderTransactions);

  // ADD PRODUCT
  $("#productForm").on("submit",function(e){

    e.preventDefault();

    const d=Object.fromEntries(new FormData(this));

    products.unshift({
      name:d.name,
      code:d.code,
      category:d.category,
      price:Number(d.price),
      minimum:Number(d.minimum),
      quantity:0,
      icon:"bi-box"
    });

    renderAll();

    bootstrap.Modal.getInstance(
      document.getElementById("productModal")
    ).hide();

    this.reset();

    showToast("Product added to this preview.");
  });

  // ADD SUPPLIER
  $("#supplierForm").on("submit",function(e){

    e.preventDefault();

    suppliers.unshift(Object.fromEntries(new FormData(this)));

    renderSuppliers();

    bootstrap.Modal.getInstance(
      document.getElementById("supplierModal")
    ).hide();

    this.reset();

    showToast("Supplier added to this preview.");
  });

  // STOCK IN AND STOCK OUT
  $("#transactionForm").on("submit",function(e){

    e.preventDefault();

    const d=Object.fromEntries(new FormData(this));
    const p=products[Number(d.product)];
    const qty=Number(d.quantity);

    if(d.type==="Stock out"&&qty>p.quantity){
      showToast("Not enough available stock for this stock-out.");
      return;
    }

    if(d.type==="Stock out"){
      p.quantity-=qty;
    }else{
      p.quantity+=qty;
    }

    transactions.unshift({
      id:"TRX-"+String(249+transactions.length-5).padStart(5,"0"),
      type:d.type,
      date:new Date().toLocaleDateString("en-US",{
        month:"short",
        day:"2-digit",
        year:"numeric"
      }),
      reference:d.reference||"—",
      items:1,
      status:"Completed"
    });

    renderAll();

    bootstrap.Modal.getInstance(
      document.getElementById("transactionModal")
    ).hide();

    this.reset();

    showToast("Transaction preview updated. No database was changed.");
  });

  // EXPORT
  $("#exportBtn,#productExport").on("click",exportProducts);

  $("#reportExport").on("click",()=>{

    exportCsv("inventory-summary-preview.csv",[
      ["Product","Code","Category","Price","Minimum","Quantity"],
      ...products.map(p=>[
        p.name,p.code,p.category,p.price,p.minimum,p.quantity
      ])
    ]);

    showToast("Preview report exported.");
  });

  // OTHER INTERACTIONS
  $("#movementPeriod").on("change",function(){
    showToast("Chart period set to "+this.value+".");
  });

  $(".report-action").on("click",function(){
    showToast($(this).data("report")+" report preview is ready to connect.");
  });

  $("#helpLink").on("click",e=>{
    e.preventDefault();
    showToast("Help center can be connected here.");
  });

  // INITIALIZE
  $("#todayLabel").text(
    new Date().toLocaleDateString("en-US",{
      month:"short",
      day:"numeric",
      year:"numeric"
    })
  );

  chart();
  renderAll();
  navigate(location.hash.replace("#","")||"dashboard");

});


  // =====================================
  // LIGHT / DARK MODE TOGGLE
  // =====================================

  // Automatically create button beside notification bell
  const themeButton = $(`
    <button
      type="button"
      id="themeToggle"
      class="theme-toggle"
      aria-label="Switch to dark mode"
      title="Switch theme">
      <i class="bi bi-moon-stars-fill"></i>
    </button>
  `);

  $(".notification-btn").after(themeButton);

  // Load saved theme
  const savedTheme = localStorage.getItem("ims-theme") || "light";

  function applyTheme(theme) {

    $("body").attr("data-theme", theme);

    if (theme === "dark") {

      $("#themeToggle")
        .html('<i class="bi bi-sun-fill"></i>')
        .attr("aria-label", "Switch to light mode")
        .attr("title", "Switch to light mode");

    } else {

      $("#themeToggle")
        .html('<i class="bi bi-moon-stars-fill"></i>')
        .attr("aria-label", "Switch to dark mode")
        .attr("title", "Switch to dark mode");

    }

    localStorage.setItem("ims-theme", theme);
  }

  // Apply saved theme when website opens
  applyTheme(savedTheme);

  // Toggle theme when clicked
  $("#themeToggle").on("click", function() {

    const currentTheme = $("body").attr("data-theme");

    const newTheme = currentTheme === "dark" ? "light" : "dark";

    applyTheme(newTheme);

    showToast(
      newTheme === "dark"
        ? "Dark mode enabled."
        : "Light mode enabled."
    );

  });

