# Script for populating the database. You can run it as:
#
#     mix ecto.seed <your-github-login>

import Algora.Factory

alias Algora.Repo
alias Algora.Util

require Logger

Application.put_env(:algora, :stripe_client, Algora.Support.StripeMock)

{:ok, github_user} =
  case System.argv() do
    [github_handle] -> Algora.Github.get_user_by_username(nil, github_handle)
    _ -> {:ok, nil}
  end

pied_piper = upsert!(:organization, [:email])

erich =
  upsert!(
    :user,
    [:provider, :provider_id],
    %{last_context: pied_piper.handle, is_admin: true}
    |> Map.merge(
      if(github_user,
        do: %{
          provider: "github",
          provider_login: github_user["login"],
          provider_id: to_string(github_user["id"]),
          provider_meta: Util.normalize_struct(github_user),
          handle: github_user["login"],
          display_name: github_user["name"],
          avatar_url: github_user["avatar_url"],
          website_url: github_user["blog"],
          twitter_url: "https://x.com/" <> github_user["twitter_username"],
          location: github_user["location"],
          bio: github_user["bio"]
        },
        else: %{}
      )
    )
    |> Map.merge(if(github_user && github_user["email"], do: %{email: github_user["email"]}, else: %{}))
  )

richard =
  upsert!(
    :user,
    [:email],
    %{
      email: "richard@example.com",
      display_name: "Richard Hendricks",
      handle: "richard",
      provider_login: "richard",
      bio: "CEO of Pied Piper. Creator of the middle-out compression algorithm.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/richard.jpg",
      tech_stack: ["Python", "C++"],
      hourly_rate_min: Money.new!(200, :USD),
      hourly_rate_max: Money.new!(300, :USD),
      hours_per_week: 40
    }
  )

dinesh =
  upsert!(
    :user,
    [:email],
    %{
      email: "dinesh@example.com",
      display_name: "Dinesh Chugtai",
      handle: "dinesh",
      provider_login: "dinesh",
      bio: "Lead Frontend Engineer at Pied Piper. Java bad, Python good.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/dinesh.png",
      tech_stack: ["Python", "JavaScript"],
      hourly_rate_min: Money.new!(150, :USD),
      hourly_rate_max: Money.new!(200, :USD),
      hours_per_week: 35
    }
  )

gilfoyle =
  upsert!(
    :user,
    [:email],
    %{
      email: "gilfoyle@example.com",
      display_name: "Bertram Gilfoyle",
      handle: "gilfoyle",
      provider_login: "gilfoyle",
      bio: "Systems Architect. Security. DevOps. Satanist.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/gilfoyle.jpg",
      tech_stack: ["Python", "Rust", "Go", "Terraform"],
      hourly_rate_min: Money.new!(180, :USD),
      hourly_rate_max: Money.new!(250, :USD),
      hours_per_week: 40
    }
  )

jared =
  upsert!(
    :user,
    [:email],
    %{
      email: "jared@example.com",
      display_name: "Jared Dunn",
      handle: "jared",
      provider_login: "jared",
      bio: "COO of Pied Piper. Former Hooli executive. Excel wizard.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/jared.png",
      tech_stack: ["Python", "SQL"],
      hourly_rate_min: Money.new!(175, :USD),
      hourly_rate_max: Money.new!(225, :USD),
      hours_per_week: 45
    }
  )

carver =
  upsert!(
    :user,
    [:email],
    %{
      email: "carver@example.com",
      display_name: "Kevin 'The Carver'",
      handle: "carver",
      provider_login: "carver",
      bio:
        "Cloud architecture specialist. If your infrastructure needs a teardown, I'm your guy. Known for my 'insane' cloud architectures and occasional server incidents.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/carver.jpg",
      tech_stack: ["Python", "Go", "Rust", "Terraform"],
      hourly_rate_min: Money.new!(200, :USD),
      hourly_rate_max: Money.new!(300, :USD),
      hours_per_week: 30,
      provider_meta: %{
        "company" => "Chaos Engineering LLC",
        "location" => "San Francisco, CA",
        "twitter_handle" => "the_real_carver"
      }
    }
  )

pied_piper_members = [erich, richard, dinesh, gilfoyle, jared]

for user <- pied_piper_members do
  upsert!(
    :member,
    [:user_id, :org_id],
    %{user_id: user.id, org_id: pied_piper.id}
  )
end

if customer_id = Algora.config([:stripe, :test_customer_id]) do
  {:ok, cus} = Stripe.Customer.retrieve(customer_id)
  {:ok, pm} = Stripe.PaymentMethod.retrieve(cus.invoice_settings.default_payment_method)

  customer =
    insert!(
      :customer,
      %{
        provider_id: cus.id,
        provider_meta: Util.normalize_struct(cus),
        name: cus.name,
        user_id: pied_piper.id
      }
    )

  _payment_method =
    insert!(
      :payment_method,
      %{
        provider_id: pm.id,
        provider_meta: Util.normalize_struct(pm),
        provider_customer_id: cus.id,
        customer_id: customer.id
      }
    )
end

if account_id = Algora.config([:stripe, :test_account_id]) do
  {:ok, acct} = Stripe.Account.retrieve(account_id)

  upsert!(
    :account,
    [:provider, :provider_id],
    %{
      provider_id: acct.id,
      provider_meta: Util.normalize_struct(acct),
      name: acct.business_profile.name,
      details_submitted: acct.details_submitted,
      charges_enabled: acct.charges_enabled,
      payouts_enabled: acct.payouts_enabled,
      country: acct.country,
      type: String.to_atom(acct.type),
      user_id: carver.id
    }
  )
end

big_head =
  upsert!(
    :user,
    [:email],
    %{
      email: "bighead@example.com",
      display_name: "Nelson Bighetti",
      handle: "bighead",
      provider_login: "bighead",
      bio: "Former Hooli executive. Accidental tech success. Stanford President.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/bighead.jpg",
      tech_stack: ["Python", "JavaScript"],
      country: "IT",
      hourly_rate_min: Money.new!(150, :USD),
      hourly_rate_max: Money.new!(200, :USD),
      hours_per_week: 25,
      provider_meta: %{
        "company" => "Stanford University",
        "location" => "Palo Alto, CA",
        "twitter_handle" => "bighead_stanford"
      }
    }
  )

jian_yang =
  upsert!(
    :user,
    [:email],
    %{
      email: "jianyang@example.com",
      display_name: "Jian Yang",
      handle: "jianyang",
      provider_login: "jianyang",
      bio: "App developer. Creator of SeeFood and Smokation.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/jianyang.jpg",
      tech_stack: ["Swift", "Python", "TensorFlow"],
      country: "HK",
      hourly_rate_min: Money.new!(125, :USD),
      hourly_rate_max: Money.new!(175, :USD),
      hours_per_week: 35,
      provider_meta: %{
        "company" => "@SeeFood",
        "location" => "Hong Kong",
        "twitter_handle" => "jianyang"
      }
    }
  )

john =
  upsert!(
    :user,
    [:email],
    %{
      email: "john@example.com",
      display_name: "John Stafford",
      handle: "john",
      provider_login: "john",
      bio: "Datacenter infrastructure expert. Rack space optimization specialist.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/john.png",
      tech_stack: ["Perl", "Terraform", "C++", "C"],
      country: "GB",
      hourly_rate_min: Money.new!(140, :USD),
      hourly_rate_max: Money.new!(190, :USD),
      hours_per_week: 40,
      provider_meta: %{
        "company" => "DataRack Solutions",
        "location" => "London, UK",
        "twitter_handle" => "johnstafford_tech"
      }
    }
  )

aly =
  upsert!(
    :user,
    [:email],
    %{
      email: "aly@example.com",
      display_name: "Aly Dutta",
      handle: "aly",
      provider_login: "aly",
      bio: "Former Hooli engineer. Expert in distributed systems and scalability.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/aly.png",
      tech_stack: ["Java", "Kotlin", "Go"],
      country: "IN",
      hourly_rate_min: Money.new!(160, :USD),
      hourly_rate_max: Money.new!(220, :USD),
      hours_per_week: 35,
      provider_meta: %{
        "company" => "Distributed Systems Inc.",
        "location" => "Bangalore, India",
        "twitter_handle" => "aly_distributed"
      }
    }
  )

for user <- [aly, big_head, jian_yang, john] do
  debit_id = Nanoid.generate()
  credit_id = Nanoid.generate()
  amount = Money.new!(Enum.random(1..10) * 10_000, :USD)

  Repo.transact(fn ->
    insert!(:transaction, %{
      id: debit_id,
      linked_transaction_id: credit_id,
      type: :debit,
      status: :succeeded,
      net_amount: amount,
      user_id: pied_piper.id,
      succeeded_at: days_from_now(0)
    })

    insert!(:transaction, %{
      id: credit_id,
      linked_transaction_id: debit_id,
      type: :credit,
      status: :succeeded,
      net_amount: amount,
      user_id: user.id,
      succeeded_at: days_from_now(0)
    })

    {:ok, :ok}
  end)
end

repos = [
  {
    "middle-out",
    [
      "Optimize algorithm performance",
      "Add support for new file types",
      "Improve error handling",
      "Implement streaming compression",
      "Add compression statistics API"
    ]
  },
  {
    "pied-piper-web",
    [
      "Fix memory leak in upload handler",
      "Implement new dashboard UI",
      "Add real-time compression stats",
      "Integrate SSO authentication",
      "Build file comparison view"
    ]
  },
  {
    "infra",
    [
      "Scale kubernetes cluster",
      "Implement auto-scaling",
      "Optimize cloud costs",
      "Set up monitoring and alerts",
      "Configure disaster recovery"
    ]
  }
]

for {repo_name, issues} <- repos do
  repo =
    insert!(:repository, %{
      name: repo_name,
      url: "https://github.com/piedpiper/#{repo_name}",
      user_id: pied_piper.id
    })

  for {issue_title, index} <- Enum.with_index(issues, 1) do
    issue =
      insert!(:ticket, %{
        type: :issue,
        repository_id: repo.id,
        title: issue_title,
        description: "We need help implementing this feature to improve our platform.",
        number: index,
        url: "https://github.com/piedpiper/#{repo_name}/issues/#{index}"
      })

    claimed = rem(index, 2) > 0
    paid = claimed and rem(index, 3) > 0

    bounties =
      [2000, 500, 400, 300, 200, 100]
      |> Enum.map(&Money.new!(&1, :USD))
      |> Enum.zip([pied_piper | pied_piper_members])
      |> Enum.map(fn {amount, sponsor} ->
        insert!(:bounty, %{
          ticket_id: issue.id,
          owner_id: sponsor.id,
          creator_id: sponsor.id,
          amount: amount,
          status: if(paid, do: :paid, else: :open)
        })
      end)

    if claimed do
      pull_request =
        insert!(:ticket, %{
          type: :pull_request,
          repository_id: repo.id,
          title: "Fix memory leak in upload handler and optimize buffer allocation",
          description: """
          This PR addresses the memory leak in the file upload handler by:
          - Implementing proper buffer cleanup in the streaming pipeline
          - Adding automatic resource disposal using with-clauses
          - Optimizing memory allocation for large file uploads
          - Adding memory usage monitoring

          Testing shows a 60% reduction in memory usage during sustained uploads.

          Key changes:
          ```python
          def process_upload(file_stream):
              try:
                  with MemoryManager.track() as memory:
                      for chunk in file_stream:
                          # Optimize buffer allocation
                          buffer = BytesIO(initial_size=chunk.size)
                          compressed = middle_out.compress(chunk, buffer)
                          yield compressed

                      memory.log_usage("Upload complete")
              finally:
                  buffer.close()
                  gc.collect()  # Force cleanup
          ```

          Closes ##{index}
          """,
          number: index + length(issues),
          url: "https://github.com/piedpiper/#{repo_name}/pull/#{index}"
        })

      group_id = Nanoid.generate()

      claimants =
        [carver, aly, big_head]
        |> Enum.zip(["0.5", "0.3", "0.2"])
        |> Enum.map(fn {user, share} -> {user, Decimal.new(share)} end)

      for {user, share} <- claimants do
        claim =
          insert!(:claim, %{
            group_id: group_id,
            group_share: share,
            user_id: user.id,
            target_id: issue.id,
            source_id: pull_request.id,
            type: :pull_request,
            status: :approved,
            url: "https://github.com/piedpiper/#{repo_name}/pull/#{index}"
          })

        if paid do
          for {pct_paid, bounty} <-
                ["1.25", "1.0", "1.0", "0.5", "0.0", "0.0"]
                |> Enum.map(&Decimal.new/1)
                |> Enum.zip(bounties) do
            debit_id = Nanoid.generate()
            credit_id = Nanoid.generate()

            net_paid = Money.mult!(bounty.amount, Decimal.mult(share, pct_paid))

            # Create transaction pairs for paid claims
            Repo.transact(fn ->
              insert!(:transaction, %{
                id: debit_id,
                linked_transaction_id: credit_id,
                bounty_id: bounty.id,
                claim_id: claim.id,
                type: :debit,
                status: :succeeded,
                net_amount: net_paid,
                user_id: bounty.owner_id,
                succeeded_at: claim.inserted_at
              })

              insert!(:transaction, %{
                id: credit_id,
                linked_transaction_id: debit_id,
                bounty_id: bounty.id,
                claim_id: claim.id,
                type: :credit,
                status: :succeeded,
                net_amount: net_paid,
                user_id: user.id,
                succeeded_at: claim.inserted_at
              })

              {:ok, :ok}
            end)
          end
        end
      end
    end
  end
end

job_postings = [
  %{
    title: "Senior Backend Engineer",
    description: "Help us scale our middle-out compression platform",
    tech_stack: ["Python", "C++", "Rust"],
    url: "https://piedpiper.com/careers/backend-engineer",
    company_name: "Pied Piper",
    company_url: "https://piedpiper.com",
    email: "jobs@piedpiper.com",
    user_id: pied_piper.id
  },
  %{
    title: "Frontend Developer",
    description: "Build beautiful interfaces for our compression platform",
    tech_stack: ["JavaScript", "React", "TypeScript"],
    url: "https://piedpiper.com/careers/frontend-developer",
    company_name: "Pied Piper",
    company_url: "https://piedpiper.com",
    email: "jobs@piedpiper.com",
    user_id: pied_piper.id
  }
]

for job_attrs <- job_postings do
  insert!(:job_posting, Map.put(job_attrs, :status, :active))
end
