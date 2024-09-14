export const Banner = () => {
    return (
        <>
            <div className="text-center mt-8 bg-secondary p-6">
                <h1 className="text-4xl my-0">Transactions</h1>
                <p className="text-neutral">
                    Select a type of transaction to create and wait for other signers to validate it.
                    <br />Then it will be executed automatically
                </p>
            </div>
        </>
    )
}

export default Banner;